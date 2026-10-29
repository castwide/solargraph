# frozen_string_literal: true

# HACK: Fix autoload issue
require 'solargraph/source/chain/link'

module Solargraph
  class Source
    #
    # Represents an expression as a single call chain at the parse
    # tree level, made up of constants, variables, and method calls,
    # each represented as a Link object.
    #
    # Computes Pins and/or ComplexTypes representing the interpreted
    # expression.
    #
    class Chain
      include Equality
      include Logging

      autoload :Link,             'solargraph/source/chain/link'
      autoload :Call,             'solargraph/source/chain/call'
      autoload :QCall,            'solargraph/source/chain/q_call'
      autoload :Variable,         'solargraph/source/chain/variable'
      autoload :ClassVariable,    'solargraph/source/chain/class_variable'
      autoload :Constant,         'solargraph/source/chain/constant'
      autoload :InstanceVariable, 'solargraph/source/chain/instance_variable'
      autoload :GlobalVariable,   'solargraph/source/chain/global_variable'
      autoload :Literal,          'solargraph/source/chain/literal'
      autoload :Head,             'solargraph/source/chain/head'
      autoload :If,               'solargraph/source/chain/if'
      autoload :Or,               'solargraph/source/chain/or'
      autoload :BlockVariable,    'solargraph/source/chain/block_variable'
      autoload :BlockSymbol,      'solargraph/source/chain/block_symbol'
      autoload :ZSuper,           'solargraph/source/chain/z_super'
      autoload :Hash,             'solargraph/source/chain/hash'
      autoload :Array,            'solargraph/source/chain/array'
      autoload :Parameter,        'solargraph/source/chain/parameter'

      @@inference_stack = []
      @@inference_depth = 0
      @@inference_invalidation_key = nil
      @@inference_cache = {}

      UNDEFINED_CALL = Chain::Call.new('<undefined>', nil)
      UNDEFINED_CONSTANT = Chain::Constant.new('<undefined>')

      # @return [::Array<Source::Chain::Link>]
      attr_reader :links

      attr_reader :node

      # @param node [Parser::AST::Node, nil]
      # @param links [::Array<Chain::Link>]
      # @param splat [Boolean]
      def initialize links, node = nil, splat = false
        @links = links.clone
        @links.push UNDEFINED_CALL if @links.empty?
        head = true
        @links.map! do |link|
          result = (head ? link.clone_head : link.clone_body)
          head = false
          result
        end
        @node = node
        @splat = splat
      end

      # @return [Chain]
      def base
        # @sg-ignore Need to add nil check here
        @base ||= Chain.new(links[0..-2])
      end

      # Determine potential Pins returned by this chain of words
      #
      # @param api_map [ApiMap]
      #
      # @param name_pin [Pin::Base] A pin representing the closure in
      #   which expression is evaluated (e.g., a Method pin, or a
      #   Module or Class pin if not run within a method - both in
      #   terms of the closure around the chain, as well as the self
      #   type used for any method calls in head position.
      #
      #   Requirements for name_pin:
      #
      #     * name_pin.context: This should be a type representing the
      #       namespace where we can look up non-local variables.  If
      #       it is a Class<X>, we will look up :class scoped
      #       instance variables.
      #
      #     * name_pin.binder: Used for method call lookups only
      #       (Chain::Call links).  For method calls as the first
      #       element in the chain, 'name_pin.binder' should be the
      #       same as name_pin.context above.  For method calls later
      #       in the chain, it changes.  (e.g., for 'b' in a.b.c, it
      #       should represent the type of 'a').
      #
      # @param locals [::Array<Pin::LocalVariable>] Any local
      #   variables / method parameters etc visible by the statement
      #
      # @return [::Array<Pin::Base>] Pins representing possible return
      #   types of this method.
      def define api_map, name_pin, locals
        return [] if undefined?

        # working_pin is the surrounding closure pin for the link
        # being processed, whose #binder method will provide the LHS /
        # 'self type' of the next link (same as the  #return_type method
        # --the type of the result so far).
        #
        # @todo ProxyType uses 'type' for the binder, but '
        working_pin = name_pin
        # @sg-ignore Need to add nil check here
        links[0..-2].each_with_index do |link, index|
          pins = link.resolve(api_map, working_pin, locals)
          type = infer_from_definitions(pins, working_pin, api_map, locals)
          type = type.without_nil if key_present?(index, api_map, name_pin, working_pin, locals)
          if type.undefined?
            logger.debug do
              "Chain#define(links=#{links.map(&:desc)}, name_pin=#{name_pin.inspect}, locals=#{locals}) => [] - undefined type from #{link.desc}"
            end
            return []
          end
          # We continue to use the context from the head pin, in case
          # we need it to, for instance, provide context for a block
          # evaluation.  However, we use the last link's return type
          # for the binder, as this is chaining off of it, and the
          # binder is now the lhs of the rhs we are evaluating.
          working_pin = Pin::ProxyType.anonymous(name_pin.context, binder: type, closure: name_pin, source: :chain)
          logger.debug do
            "Chain#define(links=#{links.map(&:desc)}, name_pin=#{name_pin.inspect}, locals=#{locals}) - after processing #{link.desc}, new working_pin=#{working_pin} with binder #{working_pin.binder}"
          end
        end
        links.last.last_context = working_pin
        # @sg-ignore https://github.com/castwide/solargraph/pull/1392
        links.last.resolve(api_map, working_pin, locals)
      end

      # @param api_map [ApiMap]
      # @param name_pin [Pin::Base] The pin for the closure in which this code runs
      # @param locals [::Array<Pin::LocalVariable>]
      # @return [ComplexType]
      # @sg-ignore
      def infer api_map, name_pin, locals
        # includes binder as it is mutable in Pin::Block
        cache_key = [node, node&.location, links, name_pin&.return_type, name_pin&.binder, locals]
        if @@inference_invalidation_key == api_map.hash
          cached = @@inference_cache[cache_key]
          return cached if cached
        else
          @@inference_invalidation_key = api_map.hash
          @@inference_cache = {}
        end
        out = infer_uncached(api_map, name_pin, locals).downcast_to_literal_if_possible
        logger.debug do
          "Chain#infer() - caching result - cache_key_hash=#{cache_key.hash}, links.map(&:hash)=#{links.map(&:hash)}, links=#{links}, cache_key.map(&:hash) = #{cache_key.map(&:hash)}, cache_key=#{cache_key}"
        end
        @@inference_cache[cache_key] = out
      end

      # @param api_map [ApiMap]
      # @param name_pin [Pin::Base]
      # @param locals [::Array<Pin::LocalVariable>]
      # @return [ComplexType, ComplexType::UniqueType]
      def infer_uncached api_map, name_pin, locals
        pins = define(api_map, name_pin, locals)
        if pins.empty?
          logger.debug do
            "Chain#infer_uncached(links=#{links.map(&:desc)}, locals=#{locals.map(&:desc)}) => undefined - no pins"
          end
          return ComplexType::UNDEFINED
        end
        # @sg-ignore https://github.com/castwide/solargraph/pull/1392
        last_context = links.last.last_context
        type = infer_from_definitions(pins, last_context, api_map, locals)
        # @sg-ignore https://github.com/apiology/solargraph/pull/286
        #   also covers: Unresolved call to without_nil on Solargraph::ComplexType, Solargraph::ComplexType::UniqueType
        type = type.without_nil if key_present?(links.length - 1, api_map, name_pin, last_context, locals)
        out = maybe_nil(type, api_map)
        logger.debug do
          "Chain#infer_uncached(links=#{links.map(&:desc)}, locals=#{locals.map(&:desc)}, " \
            "name_pin=#{name_pin}, name_pin.closure=#{name_pin&.closure&.inspect}, " \
            "name_pin.binder=#{name_pin&.binder}) => #{out.rooted_tags.inspect}"
        end
        out
      end

      # @return [Boolean]
      def literal?
        links.last.is_a?(Chain::Literal)
      end

      # @return [Boolean]
      # @sg-ignore false "return type could not be inferred"
      def require_parameter?
        # @sg-ignore false "Unresolved call to require_parameter? on Solargraph::Source::Chain::Link"
        links.last.is_a?(Chain::Parameter) && links.last.require_parameter?
      end

      def undefined?
        links.any?(&:undefined?)
      end

      def defined?
        !undefined?
      end

      # @return [Boolean]
      def constant?
        links.last.is_a?(Chain::Constant)
      end

      def splat?
        @splat
      end

      # Whether this chain's inferred type should have nil added to it
      # because a `&.` earlier in the chain might have short-circuited
      # evaluation to nil.
      #
      # A `&.` only makes the *immediate* call nil-or-normal-result; a
      # later, non-safe-navigated call in the same chain is still
      # invoked on whatever that produced. If receiver is nil at that
      # point, Ruby calls the method on nil itself instead of skipping
      # it - so nil only continues to flow through subsequent links
      # that NilClass defines as returning `self` (e.g., #tap,
      # #itself). Any other subsequent call resolves to a concrete,
      # non-nil-including type (e.g. NilClass#== returns Boolean), and
      # nil no longer needs to be tracked past that point (unless a
      # later `&.` reintroduces it).
      #
      # @param api_map [ApiMap]
      # @return [Boolean]
      def nullable? api_map
        currently_nullable = false
        links.each do |link|
          if link.nullable?
            currently_nullable = true
            next
          end
          next unless currently_nullable
          next unless link.is_a?(Chain::Call)

          pin = api_map.get_method_stack('NilClass', link.word, scope: :instance).first
          # @sg-ignore Need to add nil check here
          currently_nullable = pin.nil? || pin.return_type.tag == 'self'
        end
        currently_nullable
      end

      include Logging

      # @return [String]
      def desc
        links.map(&:desc).to_s
      end

      def to_s
        desc
      end

      include Logging

      private

      # @param pins [::Array<Pin::Base>]
      # @param name_pin [Pin::Base]
      # @param api_map [ApiMap]
      # @param locals [::Enumerable<Pin::LocalVariable>]
      # @return [ComplexType, ComplexType::UniqueType]
      def infer_from_definitions pins, name_pin, api_map, locals
        # @type [::Array<ComplexType, ComplexType::UniqueType>]
        types = []
        unresolved_pins = []
        # @todo this param tag shouldn't be needed to probe the type
        # @todo ...but given it is needed, typecheck should complain that it is needed
        # @param pin [Pin::Base]
        pins.each do |pin|
          # Avoid infinite recursion
          next if @@inference_stack.include?(pin)

          @@inference_stack.push pin
          type = pin.typify(api_map)
          @@inference_stack.pop
          if type.defined?
            if type.generic?
              # @todo even at strong, no typechecking complaint
              #   happens when a [Pin::Base,nil] is passed into a method
              #   that accepts only [Pin::Namespace] as an argument
              # @sg-ignore Need to add nil check here
              type = type.resolve_generics(pin.closure, name_pin.binder)
            end
            types << type
          else
            unresolved_pins << pin
          end
        end

        # Limit method inference recursion
        return ComplexType::UNDEFINED if @@inference_depth >= 10 && pins.first.is_a?(Pin::Method)

        @@inference_depth += 1
        # @param pin [Pin::Base]
        unresolved_pins.each do |pin|
          # Avoid infinite recursion
          next if @@inference_stack.include?(pin.identity)

          @@inference_stack.push(pin.identity)
          type = pin.probe(api_map)
          @@inference_stack.pop
          types.push type if type
        end
        @@inference_depth -= 1

        type = if types.empty?
                 ComplexType::UNDEFINED
               elsif types.length > 1
                 # Move nil to the end by convention

                 # @param a [ComplexType::UniqueType]
                 sorted = types.flat_map(&:items).sort { |a, _| a.tag == 'nil' ? 1 : 0 }
                 ComplexType.new(sorted.uniq)
               else
                 ComplexType.new(types)
               end
        if name_pin.nil? || name_pin.context.undefined?
          # up to downstream to resolve self type
          return type
        end
        type.self_to_type(name_pin.context)
      end

      # True if links[index] is an 'h[k]' lookup that a Pin::KeyLookup in
      # `locals` proves present, e.g. after 'return unless h.key?(k)'.
      # Applies only when 'h' is a Hash whose values can't be nil, and 'h'
      # and 'k' read variables or attr_readers, which return the same value
      # every time.
      #
      # @param index [Integer] position of the possible '[]' link
      # @param api_map [ApiMap]
      # @param name_pin [Pin::Base]
      # @param working_pin [Pin::Base] its binder is the receiver's type
      # @param locals [::Array<Pin::LocalVariable, Pin::KeyLookup>]
      # @return [Boolean]
      def key_present? index, api_map, name_pin, working_pin, locals
        link = links[index]
        return false unless link.is_a?(Chain::Call) && link.word == '[]' && !link.nullable? && !link.with_block?
        location = link.location
        argument = link.arguments.first
        return false unless link.arguments.length == 1 && argument && location

        facts = locals.grep(Pin::KeyLookup).select { |fact| fact.visible_at?(name_pin, location) }
        return false if facts.empty? || !non_nil_hash?(working_pin.binder, api_map)

        # the local variables 'h' and 'k' read here
        bindings = []
        receiver = steps_of(links.first(index), api_map, name_pin, locals, bindings)
        key = key_steps_of(argument, api_map, name_pin, locals, bindings)
        return false unless receiver && key

        facts.any? do |fact|
          # @sg-ignore https://github.com/apiology/solargraph/pull/358
          #   also covers: Wrong argument type for Solargraph::Source::Chain#proves?
          fact.receiver == receiver && fact.key == key && proves?(fact, bindings, api_map)
        end
      end

      # @param fact [Pin::KeyLookup] a fact about the same 'h[k]'
      # @param bindings [::Array<Pin::LocalVariable>] the local variables
      #   the lookup reads
      # @param api_map [ApiMap]
      # @return [Boolean]
      def proves? fact, bindings, api_map
        bindings.all? { |variable| fact.outer_binding?(variable) } && non_nil_value?(fact, api_map)
      end

      # @param fact [Pin::KeyLookup]
      # @param api_map [ApiMap]
      # @return [Boolean] true unless the fact comes from 'h[k] ||= v'
      #   and the type of 'v' is unknown or includes nil
      def non_nil_value? fact, api_map
        value = fact.value
        return true if value.nil?

        filename = fact.location&.filename
        range = Range.from_node(value)
        closure = fact.closure
        return false unless filename && range && closure

        locals = api_map.clip_at(filename, range.ending).locals
        type = Parser.chain(value, nil, nil).infer(api_map, closure, locals)
        type.defined? && type.to_a.none? { |t| t.namespace == 'NilClass' }
      end

      # @param key [Chain]
      # @param api_map [ApiMap]
      # @param name_pin [Pin::Base]
      # @param locals [::Array<Pin::LocalVariable, Pin::KeyLookup>]
      # @param bindings [::Array<Pin::LocalVariable>] gets the local
      #   variables `key` reads
      # @return [::Array<::Array>, nil] see Pin::KeyLookup#key
      def key_steps_of key, api_map, name_pin, locals, bindings
        literal = key.links.first
        if key.links.length == 1 && literal.is_a?(Chain::Literal)
          return Pin::KeyLookup.key_steps_from_node(literal.node)
        end

        steps_of(key.links, api_map, name_pin, locals, bindings)
      end

      # @param chain_links [::Array<Chain::Link>]
      # @param api_map [ApiMap]
      # @param name_pin [Pin::Base]
      # @param locals [::Array<Pin::LocalVariable, Pin::KeyLookup>]
      # @param bindings [::Array<Pin::LocalVariable>] gets the local
      #   variables `chain_links` read
      # @return [::Array<::Array>, nil] see Pin::KeyLookup#receiver, or
      #   nil unless each link reads a variable or an attr_reader
      def steps_of chain_links, api_map, name_pin, locals, bindings
        steps = []
        chain_links.each_with_index do |link, index|
          # 'self.table' reads the same attr_reader as 'table'
          next if index.zero? && link.is_a?(Chain::Head) && link.word == 'self'

          step = step_of(link, chain_links.first(index + 1), api_map, name_pin, locals,
                         on_self: steps.empty?, bindings: bindings)
          return nil unless step

          steps.push step
        end
        steps unless steps.empty?
      end

      # @param link [Chain::Link]
      # @param prefix [::Array<Chain::Link>] the links up to and including `link`
      # @param api_map [ApiMap]
      # @param name_pin [Pin::Base]
      # @param locals [::Array<Pin::LocalVariable, Pin::KeyLookup>]
      # @param on_self [Boolean] true if `link` has no receiver but self
      # @param bindings [::Array<Pin::LocalVariable>] gets the local
      #   variables `link` reads
      # @return [::Array, nil] e.g. [:lvar, :h] or [:self_call, :table]
      def step_of link, prefix, api_map, name_pin, locals, on_self:, bindings:
        return [:ivar, link.word.to_sym] if link.is_a?(Chain::InstanceVariable)
        return [:cvar, link.word.to_sym] if link.is_a?(Chain::ClassVariable)
        return unless link.is_a?(Chain::Call) && !link.nullable? && link.arguments.empty? && !link.with_block?

        # a bare 'table' chains the same way whether it reads a local or
        # calls a method, so tell them apart by what it resolves to
        pins = Chain.new(prefix).define(api_map, name_pin, locals)
        return if pins.empty?
        if prefix.length == 1 && pins.all?(Pin::LocalVariable)
          location = link.location
          return unless location

          # every same-named variable in sight, as #define merges a block
          # parameter with the outer variable it shadows
          bindings.concat(locals.grep(Pin::LocalVariable).select do |pin|
            pin.name == link.word && pin.visible_at?(name_pin, location)
          end)
          return [:lvar, link.word.to_sym]
        end
        return unless pins.all? { |pin| pin.is_a?(Pin::Method) && pin.attribute? }

        [on_self ? :self_call : :call, link.word.to_sym]
      end

      # @param type [ComplexType, ComplexType::UniqueType]
      # @param api_map [ApiMap]
      # @return [Boolean] true for a Hash whose declared values exclude
      #   nil, e.g. Hash{String => Integer}
      def non_nil_hash? type, api_map
        type.defined? && type.to_a.all? do |t|
          api_map.super_and_sub?('Hash', t.name) &&
            # 'nil' can arrive spelled 'NilClass'
            t.value_types.none? { |value| value.to_a.any? { |u| u.namespace == 'NilClass' } }
        end
      end

      # @param type [ComplexType, ComplexType::UniqueType]
      # @param api_map [ApiMap]
      # @return [ComplexType, ComplexType::UniqueType]
      def maybe_nil type, api_map
        return type if type.undefined? || type.void? || type.nullable?
        return type unless nullable?(api_map)
        ComplexType.new(type.items + [ComplexType::NIL])
      end

      protected

      # @sg-ignore Fix "Not enough arguments to Module#protected"
      def equality_fields
        [links, node]
      end
    end
  end
end
