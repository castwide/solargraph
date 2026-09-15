# frozen_string_literal: true

module Solargraph
  # A container for type data based on YARD type tags.
  #
  class ComplexType
    GENERIC_TAG_NAME = 'generic'

    QUOTE_CHARACTERS = ['"', "'"].freeze

    # @!parse
    #   include TypeMethods
    include Equality

    autoload :Conformance, 'solargraph/complex_type/conformance'
    autoload :TypeMethods, 'solargraph/complex_type/type_methods'
    autoload :UniqueType,  'solargraph/complex_type/unique_type'

    # @param types [Array<UniqueType, ComplexType>]
    def initialize types = [UniqueType::UNDEFINED]
      # @todo @items here should not need an annotation
      # @type [Array<UniqueType>]
      items = types.flat_map(&:items).uniq(&:rooted_tags)
      if items.any? { |i| i.name == 'false' } && items.any? { |i| i.name == 'true' }
        items.delete_if { |i| %w[false true].include?(i.name) }
        items.unshift(UniqueType::BOOLEAN)
      end
      # @type [Array<UniqueType>]
      items = [UniqueType::UNDEFINED] if items.any?(&:undefined?)
      # @todo shouldn't need this cast - if statement above adds an 'Array' type
      # @type [Array<UniqueType>]
      @items = items
    end

    # @param api_map [ApiMap]
    # @param gates [Array<String>]
    #
    # @return [ComplexType]
    def qualify api_map, *gates
      red = reduce_object
      types = red.unioned_items.map do |t|
        next t if %w[nil void undefined].include?(t.rooted_tags)
        next t if ['::Boolean'].include?(t.rooted_tags)
        t.unalias_and_qualify(api_map, *gates)
      end
      ComplexType.new(types).reduce_object
    end

    # @param api_map [ApiMap]
    # @param gates [Array<String>]
    # @return [ComplexType]
    def unalias_and_qualify api_map, *gates
      ComplexType.new(items.map { |t| t.unalias_and_qualify(api_map, *gates) })
    end

    # Pins for calling +word+ on each alternative of this union
    # (loose_unions allows leniency).
    #
    # @param word [String]
    # @param api_map [ApiMap]
    # @yieldparam conjuncts [Array<ComplexType>] the conjuncts of an intersection
    # @yieldreturn [Array<ComplexType>] the conjuncts to dispatch on
    # @return [Array<Pin::Base>]
    def method_stack_pins word, api_map, &narrow_conjuncts
      pin_groups = @items.map { |item| item.method_stack_pins(word, api_map, &narrow_conjuncts) }
      return [] if !api_map.loose_unions && pin_groups.any?(&:nil?)

      # Dedup on path *and* return type: alternatives can share a
      # path (e.g. same generic method on different instantiations).
      # @param p [Pin::Base]
      pin_groups.compact.flatten.uniq { |p| [p.path, p.return_type.tag] }
    end

    # @param generics_to_resolve [Enumerable<String>]]
    # @param context_type [ComplexType, ComplexType::UniqueType, nil]
    # @param resolved_generic_values [Hash{String => ComplexType}] Added to as types are encountered or resolved
    # @return [self]
    def resolve_generics_from_context generics_to_resolve, context_type, resolved_generic_values: {}
      return self unless generic?

      ComplexType.new(@items.map do |i|
        i.resolve_generics_from_context(generics_to_resolve, context_type,
                                        resolved_generic_values: resolved_generic_values)
      end)
    end

    # @return [String]
    def to_rbs
      ((@items.length > 1 ? '(' : '') +
       @items.map(&:to_rbs).join(' | ') +
       (@items.length > 1 ? ')' : ''))
    end

    # @param dst [ComplexType, ComplexType::UniqueType]
    # @return [ComplexType]
    def self_to_type dst
      object_type_dst = dst.reduce_class_type
      transform do |t|
        next t if t.name != 'self'
        object_type_dst
      end
    end

    # @yieldparam [UniqueType]
    # @return [void]
    # @overload each_unique_type()
    #   @return [Enumerator<UniqueType>]
    def each_unique_type &block
      return enum_for(__method__) unless block_given?

      @items.each do |item|
        item.each_unique_type(&block)
      end
    end

    # @param new_name [String, nil]
    # @param make_rooted [Boolean, nil]
    # @param new_key_types [Array<ComplexType>, nil]
    # @param make_rooted [Boolean, nil]
    # @param new_subtypes [Array<ComplexType>, nil]
    # @return [self]
    def recreate new_name: nil, make_rooted: nil, new_key_types: nil, new_subtypes: nil
      ComplexType.new(items.map do |ut|
                        ut.recreate(new_name: new_name,
                                    make_rooted: make_rooted,
                                    new_key_types: new_key_types,
                                    new_subtypes: new_subtypes)
                      end)
    end

    # @return [Array<ComplexType::UniqueType>]
    def unioned_items
      @items
    end

    # Pairs this union up with another type member by member, yields
    # each pair, and reassembles the results into one union.
    #
    # @param other [ComplexType, ComplexType::UniqueType]
    # @yieldparam mine [ComplexType, ComplexType::UniqueType]
    # @yieldparam theirs [ComplexType, ComplexType::UniqueType]
    # @yieldreturn [ComplexType, ComplexType::UniqueType]
    # @return [ComplexType, ComplexType::UniqueType]
    def combine_via other, &block
      # @param members [Array<ComplexType, ComplexType::UniqueType>]
      gather = ->(members) { ComplexType.union(*members) }
      ComplexType.union(*TypeMethods.combine_members(unioned_items, other.unioned_items, gather, &block))
    end

    # @return [String]
    def namespace
      # cache this attr for high frequency call
      @namespace ||= method_missing(:namespace).to_s
    end

    # @return [Array<String>]
    def namespaces
      @items.map(&:namespace)
    end

    # @param name [Symbol]
    #
    # @return [Object, nil]
    # @param [Array<Object>] args
    def method_missing name, *args, &block
      return if @items.first.nil?
      return @items.first.send(name, *args, &block) if respond_to_missing?(name)
      super
    end

    # @param name [Symbol]
    # @param include_private [Boolean]
    def respond_to_missing? name, include_private = false
      TypeMethods.public_method_defined?(name) || super
    end

    def to_s
      items.map(&:tag).join(', ')
    end

    # @return [String]
    def tags
      items.map(&:tag).join(', ')
    end

    # @return [String]
    def simple_tags
      simplify_literals.tags
    end

    def literal?
      @items.any?(&:literal?)
    end

    # @return [ComplexType]
    def downcast_to_literal_if_possible
      return self
      ComplexType.new(items.map(&:downcast_to_literal_if_possible))
    end

    # @return [String]
    def desc
      rooted_tags
    end

    # @param api_map [ApiMap]
    # @param expected [ComplexType, ComplexType::UniqueType]
    # @param situation [:method_call, :return_type, :assignment]
    # @param rules [Array<:allow_subtype_skew, :allow_empty_params, :allow_reverse_match, :allow_any_match, :allow_undefined, :allow_unresolved_generic, :allow_unmatched_interface>]
    #
    #   allow_subtype_skew: if not provided, check if any subtypes of
    #     the expected type match the inferred type
    #
    #   allow_reverse_match: check if any subtypes
    #     of the expected type match the inferred type
    #
    #   allow_empty_params: allow a general inferred type without
    #     parameters to conform to a more specific expected type
    #
    #   allow_any_match: any unique type matched in the inferred
    #     qualifies as a match
    #
    #   allow_undefined: treat undefined as a wildcard that matches
    #     anything
    #
    # @param variance [:invariant, :covariant, :contravariant]
    # @return [Boolean]
    def conforms_to? api_map, expected,
                     situation,
                     rules = [],
                     variance: erased_variance(situation)
      expected = expected.downcast_to_literal_if_possible
      inferred = downcast_to_literal_if_possible

      return duck_types_match?(api_map, expected, inferred, rules) if expected.duck_type?

      if rules.include? :allow_any_match
        inferred.items.any? do |inf|
          inf.conforms_to?(api_map, expected, situation, rules,
                           variance: variance)
        end
      else
        inferred.items.all? do |inf|
          inf.conforms_to?(api_map, expected, situation, rules,
                           variance: variance)
        end
      end
    end

    # What an inferred type must do to satisfy this union: conform to
    # any one member.
    #
    # @param inferred [ComplexType, ComplexType::UniqueType]
    # @param api_map [ApiMap]
    # @param situation [:method_call, :assignment, :return_type]
    # @param rules [Array<Symbol>]
    # @param variance [:invariant, :covariant, :contravariant]
    # @return [Boolean]
    def satisfied_by? inferred, api_map, situation, rules = [],
                      variance: inferred.erased_variance(situation)
      # A duck-typed expectation is structural, so it is checked against
      # the inferred type as a whole rather than member by member.
      return duck_types_match?(api_map, self, inferred, rules) if duck_type?

      unioned_items.any? do |item|
        inferred.conforms_to?(api_map, item, situation, rules, variance: variance)
      end
    end

    # Whether this union conforms to a single named expectation: every
    # member must, since any of them could be the runtime type.
    #
    # @param expected [ComplexType::UniqueType]
    # @param api_map [ApiMap]
    # @param situation [:method_call, :assignment, :return_type]
    # @param rules [Array<Symbol>]
    # @param variance [:invariant, :covariant, :contravariant]
    # @return [Boolean]
    def conforms_to_unique? expected, api_map, situation, rules = [],
                            variance: erased_variance(situation)
      if rules.include? :allow_any_match
        return unioned_items.any? do |item|
          item.conforms_to_unique?(expected, api_map, situation, rules, variance: variance)
        end
      end

      unioned_items.all? do |item|
        item.conforms_to_unique?(expected, api_map, situation, rules, variance: variance)
      end
    end

    # @param api_map [ApiMap]
    # @param expected [ComplexType, UniqueType]
    # @param inferred [ComplexType, UniqueType]
    # @param rules [Array<Symbol>]
    # @return [Boolean]
    def duck_types_match? api_map, expected, inferred, rules = []
      raise ArgumentError, 'Expected type must be duck type' unless expected.duck_type?
      allow_any_match = rules.include?(:allow_any_match)
      expected.items.each do |exp|
        next unless exp.duck_type?
        quack = exp.to_s[1..] || ''
        matched = allow_any_match ? inferred.items.any? { |inf| inf.provides_duck_method?(api_map, quack) } : inferred.items.all? { |inf| inf.provides_duck_method?(api_map, quack) }
        return false unless matched
      end
      true
    end

    # Rebuilds this union with each named type replaced by what the
    # block returns for it.  A block returning nil makes the whole type
    # unresolvable, since a union with a missing member is not one.
    #
    # @yieldparam named_type [ComplexType::UniqueType]
    # @yieldreturn [ComplexType::UniqueType, nil]
    # @return [ComplexType, nil]
    def qualify_parts &block
      parts = unioned_items.map { |item| item.qualify_parts(&block) }
      ComplexType.new(parts) unless parts.any?(&:nil?)
    end

    # The methods reachable on a value of this union, from +context+.
    #
    # Every member offers its own, and they are pooled rather than
    # intersected: a caller wanting only what all members provide has to
    # narrow the result itself, which is what the loose_unions rule does.
    #
    # @param api_map [ApiMap]
    # @param context [String] Fully qualified namespace the type is referenced from
    # @param internal [Boolean] True to include private methods
    # @return [Array<Pin::Base>]
    def methods_visible_from api_map, context, internal
      unioned_items.flat_map { |item| item.methods_visible_from(api_map, context, internal) }.uniq
    end

    # Whether every member of this union provides +quack+, since any of
    # them could be the runtime type.
    #
    # @param api_map [ApiMap]
    # @param quack [String]
    # @return [Boolean]
    def provides_duck_method? api_map, quack
      unioned_items.all? { |item| item.provides_duck_method?(api_map, quack) }
    end

    # @return [String]
    def rooted_tags
      items.map(&:rooted_tag).join(', ')
    end

    def selfy?
      @items.any?(&:selfy?)
    end

    def generic?
      items.any?(&:generic?)
    end

    # @return [self]
    def simplify_literals
      ComplexType.new(items.map(&:simplify_literals))
    end

    # @param new_name [String, nil]
    # @yieldparam t [UniqueType]
    # @yieldreturn [UniqueType]
    # @return [ComplexType]
    def transform new_name = nil, &transform_type
      if new_name&.start_with?('::')
        raise "Please remove leading :: and set rooted with recreate() instead - #{new_name}"
      end
      ComplexType.new(items.map { |ut| ut.transform(new_name, &transform_type) })
    end

    # @param named_types [Hash{String => ComplexType}]
    # @return [ComplexType]
    def expand named_types
      ComplexType.new(items.map { |ut| ut.expand(named_types) })
    end

    # @return [self]
    def force_rooted
      transform do |t|
        t.recreate(make_rooted: true)
      end
    end

    # @param definitions [Pin::Namespace, Pin::Method]
    # @param context_type [ComplexType]
    # @return [ComplexType]
    def resolve_generics definitions, context_type
      result = @items.map { |i| i.resolve_generics(definitions, context_type) }
      ComplexType.new(result)
    end

    def nullable?
      @items.any?(&:nil_type?)
    end

    # @return [ComplexType]
    def without_nil
      new_items = @items.reject(&:nil_type?)
      return ComplexType::UNDEFINED if new_items.empty?
      ComplexType.new(new_items)
    end

    # @return [Array<ComplexType>]
    def all_params
      @items.first.all_params || []
    end

    # @return [ComplexType]
    def reduce_class_type
      # [type] not type: flat_map asks a bare block result for to_ary.
      new_items = items.flat_map do |type|
        next [type] unless %w[Module Class].include?(type.name)
        next [type] if type.all_params.empty?

        type.all_params
      end
      ComplexType.new(new_items)
    end

    # every type and subtype in this union have been resolved to be
    # fully qualified
    def all_rooted?
      items.all?(&:all_rooted?)
    end

    # @param other [ComplexType, UniqueType]
    def erased_version_of? other
      return false if items.length != 1 || other.items.length != 1

      @items.first.erased_version_of?(other.items.first)
    end

    # every top-level type has resolved to be fully qualified; see
    # #all_rooted? to check their subtypes as well
    def rooted?
      items.all?(&:rooted?)
    end

    attr_reader :items

    # @param exclude_types [ComplexType, nil]
    # @param api_map [ApiMap]
    # @return [ComplexType, self]
    def exclude exclude_types, api_map
      return self if exclude_types.nil?

      types = items - exclude_types.items
      types = [ComplexType::UniqueType::UNDEFINED] if types.empty?
      ComplexType.new(types)
    end

    # Flow-sensitive type narrowing: given a type learned from a
    # runtime guard (e.g. `x.is_a?(Foo)`), refines this type down to
    # the more specific of each compatible pair. When neither side
    # subtypes the other but one is confirmed to be a mix-in, both
    # facts hold at once, so the pair becomes an Intersection; any
    # other pair is dropped (see #mixin_pairing?). UNDEFINED results
    # only when every pair is dropped or empty.
    #
    # @see https://www.typescriptlang.org/docs/handbook/2/narrowing.html
    #
    # @param narrowing_type [ComplexType, ComplexType::UniqueType, nil]
    # @param api_map [ApiMap]
    # @return [self, ComplexType::UniqueType]
    def narrow_with narrowing_type, api_map
      return self if narrowing_type.nil?
      return narrowing_type if undefined?
      types = []
      # try to find common types via conformance
      items.each do |ut|
        narrowing_type.items.each do |candidate|
          if candidate.conforms_to?(api_map, ut, :assignment)
            types << candidate
          elsif ut.conforms_to?(api_map, candidate, :assignment)
            types << ut
          elsif mixin_pairing?(api_map, ut, candidate)
            types << UniqueType::Intersection.new([ComplexType.new([ut]), ComplexType.new([candidate])])
          end
        end
      end
      types = [ComplexType::UniqueType::UNDEFINED] if types.empty?
      ComplexType.new(types)
    end

    protected

    def equality_fields
      [self.class, items]
    end

    # @return [ComplexType]
    def reduce_object
      new_items = items.flat_map do |ut|
        next [ut] if ut.name != 'Object' || ut.subtypes.empty?
        ut.subtypes
      end
      ComplexType.new(new_items)
    end

    def bottom?
      @items.all?(&:bot?)
    end

    # Whether combining these two into an intersection is safe. Only
    # true when at least one side is *positively confirmed* to be a
    # mix-in, since any class can pick up any module. Two concrete
    # classes are impossible (an object has exactly one class), and a
    # namespace with no pin is unverifiable, so both are false and
    # narrow_with drops the pair.
    #
    # @param api_map [ApiMap]
    # @param declared [ComplexType::UniqueType]
    # @param candidate [ComplexType::UniqueType]
    # @return [Boolean]
    def mixin_pairing? api_map, declared, candidate
      namespace_kind(api_map, declared) == :module || namespace_kind(api_map, candidate) == :module
    end

    # @param api_map [ApiMap]
    # @param unique_type [ComplexType::UniqueType]
    # @sg-ignore flow sensitive typing needs to infer Enumerable#find's block return type from an is_a? check
    # @return [:class, :module, nil] nil when the namespace has no pin
    def namespace_kind api_map, unique_type
      pin = api_map.get_path_pins(unique_type.namespace).find { |p| p.is_a?(Pin::Namespace) }
      pin&.type
    end

    class << self
      # Parse type strings into a ComplexType.
      #
      # @example
      #   ComplexType.parse 'String', 'Foo', 'nil' #=> [String, Foo, nil]
      #
      # @param partial [Boolean] if true, method is receiving a string
      #   that will be used inside another ComplexType.  It returns
      #   arrays of ComplexTypes instead of a single cohesive one.
      #   Consumers should not need to use this parameter; it should
      #   only be used internally.
      # @param strings [Array<String>] The type definitions to parse
      # @return [ComplexType]
      # # @overload parse(*strings, partial: false)
      # #  @todo Need ability to use a literal true as a type below
      # #  @param partial [Boolean] True if the string is part of a another type
      # #  @return [Array<UniqueType>]
      # @sg-ignore To be able to select the right signature above,
      #   Chain::Call needs to know the decl type (:arg, :optarg,
      #   :kwarg, etc) of the arguments given, instead of just having
      #   an array of Chains as the arguments.
      def parse *strings, partial: false
        # @type [Hash{Array<String> => ComplexType, Array<ComplexType::UniqueType>}]
        @cache ||= {}
        unless partial
          cached = @cache[strings]
          return cached unless cached.nil?
        end
        # @types [Array<ComplexType::UniqueType>]
        types = []
        key_types = nil
        strings.each do |type_string|
          point_stack = 0
          curly_stack = 0
          paren_stack = 0
          bracket_stack = 0
          base = String.new
          subtype_string = String.new
          # @type [Array<ComplexType>]
          conjuncts = []
          # @type [Array<ComplexType, ComplexType::UniqueType>]
          disjuncts = []
          # the open quote character of the string literal being read
          # (e.g. `"Index"`), or nil outside one
          # @type [String, nil]
          quote = nil
          # @param char [String]
          type_string&.each_char do |char|
            if quote
              # inside a string literal every character is content, so
              # separators and brackets carry no syntactic meaning
              quote = nil if char == quote
            elsif QUOTE_CHARACTERS.include?(char)
              quote = char
            elsif char == '='
              # raise ComplexTypeError, "Invalid = in type #{type_string}" unless curly_stack > 0
            elsif char == '<'
              point_stack += 1
            elsif char == '>'
              if subtype_string.end_with?('=') && curly_stack.positive?
                subtype_string += char
              elsif base.end_with?('=')
                raise ComplexTypeError, 'Invalid hash thing' unless key_types.nil?
                # @sg-ignore Need to add nil check here
                disjuncts.push close_intersection(conjuncts, finish_atom(base[0..-2], subtype_string))
                types.push close_disjunction(disjuncts)
                # @todo this should either expand key_type's type
                #   automatically or complain about not being
                #   compatible with key_type's type in type checking
                key_types = types
                # @type [Array<ComplexType::UniqueType, ComplexType>]
                types = []
                # @type [Array<ComplexType>]
                conjuncts = []
                # @type [Array<ComplexType, ComplexType::UniqueType>]
                disjuncts = []
                base.clear
                subtype_string.clear
                next
              else
                raise ComplexTypeError, "Invalid close in type #{type_string}" if point_stack.zero?
                point_stack -= 1
                subtype_string += char
              end
              next
            elsif char == '{'
              curly_stack += 1
            elsif char == '}'
              curly_stack -= 1
              subtype_string += char
              raise ComplexTypeError, "Invalid close in type #{type_string}" if curly_stack.negative?
              next
            elsif char == '('
              paren_stack += 1
            elsif char == ')'
              paren_stack -= 1
              subtype_string += char
              raise ComplexTypeError, "Invalid close in type #{type_string}" if paren_stack.negative?
              next
            elsif char == '[' &&
                  (bracket_stack.positive? ||
                   (base.strip.empty? && point_stack.zero? && curly_stack.zero? && paren_stack.zero?))
              # Only a fresh atom (blank base, not already nested in
              # <>/{}/()) can start a `[...]` group - matching
              # finish_atom's own precondition. Otherwise `[` is just an
              # ordinary character, e.g. part of a literal type like
              # `"[]"`, which has no concept of grouping.
              bracket_stack += 1
            elsif char == ']' && bracket_stack.positive?
              bracket_stack -= 1
              subtype_string += char
              next
            elsif char == '&' && top_level?(point_stack, curly_stack, paren_stack, bracket_stack)
              conjuncts.push ComplexType.new([finish_atom(base, subtype_string)])
              base.clear
              subtype_string.clear
              next
            elsif char == '|' && top_level?(point_stack, curly_stack, paren_stack, bracket_stack)
              disjuncts.push close_intersection(conjuncts, finish_atom(base, subtype_string))
              conjuncts = []
              base.clear
              subtype_string.clear
              next
            elsif char == ',' && top_level?(point_stack, curly_stack, paren_stack, bracket_stack)
              disjuncts.push close_intersection(conjuncts, finish_atom(base, subtype_string))
              types.push close_disjunction(disjuncts)
              conjuncts = []
              disjuncts = []
              base.clear
              subtype_string.clear
              next
            end
            if top_level?(point_stack, curly_stack, paren_stack, bracket_stack)
              base.concat char
            else
              subtype_string.concat char
            end
          end
          raise ComplexTypeError, "Unclosed string literal in #{type_string}" if quote
          if point_stack != 0 || curly_stack != 0 || paren_stack != 0 || bracket_stack != 0
            raise ComplexTypeError,
                  "Unclosed subtype in #{type_string}"
          end
          disjuncts.push close_intersection(conjuncts, finish_atom(base, subtype_string))
          types.push close_disjunction(disjuncts)
        end
        unless key_types.nil?
          raise ComplexTypeError, 'Invalid use of key/value parameters' unless partial
          return key_types if types.empty?
          return [key_types, types]
        end
        result = partial ? types : ComplexType.new(types)
        @cache[strings] = result unless partial
        result
      end

      # Builds a union of the given types, dropping duplicates. A
      # lone type comes back as itself rather than as a union of one,
      # so union(A, A) is A.
      #
      # @param types [Array<ComplexType, ComplexType::UniqueType>]
      # @return [ComplexType, ComplexType::UniqueType]
      def union *types
        items = types.flat_map(&:items).uniq(&:rooted_tags)
        return items.fetch(0) if items.length == 1
        ComplexType.new(items)
      end

      # @param strings [Array<String>]
      # @return [ComplexType]
      def try_parse *strings
        parse(*strings)
      rescue ComplexTypeError => e
        Solargraph.logger.info "Error parsing complex type `#{strings.join(', ')}`: #{e.message}"
        ComplexType::UNDEFINED
      end

      private

      # @param point_stack [Integer]
      # @param curly_stack [Integer]
      # @param paren_stack [Integer]
      # @param bracket_stack [Integer]
      # @return [Boolean]
      def top_level? point_stack, curly_stack, paren_stack, bracket_stack
        point_stack.zero? && curly_stack.zero? && paren_stack.zero? && bracket_stack.zero?
      end

      # Resolves one type atom - either an ordinary named type (`base`
      # plus its optional `<...>`/`(...)`/`{...}` parameter substring),
      # or a standalone `[...]` grouping with no leading name, used to
      # override the default order of operations (e.g. `[Foo | Bar] &
      # Baz`, where `[...]` is the only way to mark where the union
      # ends). A bracket group's content is parsed recursively via
      # ComplexType.parse and substituted directly, since it can
      # itself be a union or an intersection.
      #
      # @param base [String]
      # @param subtype_string [String]
      # @return [ComplexType::UniqueType, ComplexType]
      def finish_atom base, subtype_string
        base = base.strip
        subtype_string = subtype_string.strip
        if base.empty? && subtype_string.start_with?('[')
          raise ComplexTypeError, "Unclosed bracket group in #{subtype_string}" unless subtype_string.end_with?(']')
          return ComplexType.new(ComplexType.parse(subtype_string[1..-2], partial: true))
        end
        UniqueType.parse(base, subtype_string)
      end

      # Wraps a just-parsed atom together with any pending
      # intersection conjuncts (types seen so far in this disjunct,
      # separated by `&`) into a single UniqueType. Each conjunct is
      # a ComplexType (see UniqueType::Intersection), so the final
      # parsed type is promoted to a single-item ComplexType too.
      #
      # @param conjuncts [Array<ComplexType>]
      # @param final_type [ComplexType::UniqueType, ComplexType]
      # @return [ComplexType::UniqueType, ComplexType]
      def close_intersection conjuncts, final_type
        return final_type if conjuncts.empty?
        UniqueType::Intersection.new(conjuncts + [ComplexType.new([final_type])])
      end

      # Collapses the disjuncts of a union type (`A | B`) seen so far
      # into a single value to push into the enclosing types/subtypes
      # list - a bare type when `|` was never used, a multi-item
      # ComplexType union otherwise. A top-level `,` in an
      # already-implicit-union context (Array<...>, hash key/value
      # lists, the top-level types list) reduces to the same thing,
      # since those contexts flatten commas into one union anyway.
      #
      # @param disjuncts [Array<ComplexType, ComplexType::UniqueType>]
      # @return [ComplexType::UniqueType, ComplexType]
      def close_disjunction disjuncts
        union(*disjuncts)
      end
    end

    VOID = ComplexType.parse('void')
    UNDEFINED = ComplexType.parse('undefined')
    SYMBOL = ComplexType.parse('::Symbol')
    ROOT = ComplexType.parse('::Class<>')
    NIL = ComplexType.parse('nil')
    SELF = ComplexType.parse('self')
    BOOLEAN = ComplexType.parse('::Boolean')
    BOT = ComplexType.parse('bot')

    private

    # @todo This is a quick and dirty hack that forces `self` keywords
    #   to reference an instance of their class and never the class itself.
    #   This behavior may change depending on which result is expected
    #   from YARD conventions. See https://github.com/lsegal/yard/issues/1257
    # @param dst [String]
    # @return [String]
    def reduce_class dst
      dst = dst.sub(/^(Class|Module)</, '').sub(/>$/, '') while dst =~ /^(Class|Module)<(.*?)>$/
      dst
    end
  end
end
