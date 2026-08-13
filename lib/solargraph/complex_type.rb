# frozen_string_literal: true

module Solargraph
  # A container for type data based on YARD type tags.
  #
  class ComplexType
    GENERIC_TAG_NAME = 'generic'
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
      items = types.flat_map(&:items).uniq(&:to_s)
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
      types = red.items.map do |t|
        next t if %w[nil void undefined].include?(t.name)
        next t if ['::Boolean'].include?(t.rooted_name)
        api_map.unalias(t.name) || t.qualify(api_map, *gates)
      end
      ComplexType.new(types).reduce_object
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

    # @return [UniqueType]
    def first
      @items.first
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
    # @yieldreturn [UniqueType]
    # @return [Array<UniqueType>]
    # @sg-ignore Declared return type
    #   ::Array<::Solargraph::ComplexType::UniqueType> does not match
    #   inferred type ::Array<::Proc> for Solargraph::ComplexType#map
    def map &block
      @items.map(&block)
    end

    # @yieldparam [UniqueType]
    # @return [Enumerable<UniqueType>]
    def each &block
      @items.each(&block)
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
      ComplexType.new(map do |ut|
                        ut.recreate(new_name: new_name,
                                    make_rooted: make_rooted,
                                    new_key_types: new_key_types,
                                    new_subtypes: new_subtypes)
                      end)
    end

    # @return [Integer]
    def length
      @items.length
    end

    # @return [Array<UniqueType>]
    def to_a
      @items
    end

    # @param index [Integer]
    # @return [UniqueType]
    def [] index
      @items[index]
    end

    # @return [Array<UniqueType>]
    def select &block
      @items.select(&block)
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
      map(&:tag).join(', ')
    end

    # @return [String]
    def tags
      map(&:tag).join(', ')
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

      return duck_types_match?(api_map, expected, inferred) if expected.duck_type?

      if rules.include? :allow_any_match
        inferred.any? do |inf|
          inf.conforms_to?(api_map, expected, situation, rules,
                           variance: variance)
        end
      else
        inferred.all? do |inf|
          inf.conforms_to?(api_map, expected, situation, rules,
                           variance: variance)
        end
      end
    end

    # @param api_map [ApiMap]
    # @param expected [ComplexType, UniqueType]
    # @param inferred [ComplexType, UniqueType]
    # @return [Boolean]
    def duck_types_match? api_map, expected, inferred
      raise ArgumentError, 'Expected type must be duck type' unless expected.duck_type?
      expected.each do |exp|
        next unless exp.duck_type?
        quack = exp.to_s[1..]
        return false unless inferred.all? { |inf| unique_type_quacks?(api_map, quack, inf) }
      end
      true
    end

    # Intersection#namespace/#scope only report the first conjunct,
    # which loses the "any one conjunct satisfies" semantics an
    # intersection needs against a duck-typed expectation - e.g. a
    # mock stubbed to satisfy an interface, typed `SomeMockClass &
    # #some_method`, has to be checked against every conjunct rather
    # than the first one. A conjunct is itself a full ComplexType (RBS
    # allows a union as one member of an intersection), so a union
    # conjunct only counts as satisfying the duck type if every one of
    # its own alternatives does.
    #
    # @param api_map [ApiMap]
    # @param quack [String, nil]
    # @param unique_type [ComplexType::UniqueType]
    # @return [Boolean]
    def unique_type_quacks? api_map, quack, unique_type
      if unique_type.is_a?(UniqueType::Intersection)
        return unique_type.conjuncts.any? do |conjunct|
          conjunct.all? { |ut| unique_type_quacks?(api_map, quack, ut) }
        end
      end
      # A duck-typed conjunct only vouches for the one method its own
      # tag names - it has no namespace to look other methods up on.
      return unique_type.to_s[1..] == quack if unique_type.duck_type?
      return false if quack.nil?
      !api_map.get_method_stack(unique_type.namespace, quack, scope: unique_type.scope).empty?
    end

    # @return [String]
    def rooted_tags
      map(&:rooted_tag).join(', ')
    end

    # @yieldparam [UniqueType]
    def all? &block
      @items.all?(&block)
    end

    # @yieldparam [UniqueType]
    # @yieldreturn [Boolean]
    # @return [Boolean]
    def any? &block
      @items.compact.any?(&block)
    end

    def selfy?
      @items.any?(&:selfy?)
    end

    def generic?
      any?(&:generic?)
    end

    # @return [self]
    def simplify_literals
      ComplexType.new(map(&:simplify_literals))
    end

    # @param new_name [String, nil]
    # @yieldparam t [UniqueType]
    # @yieldreturn [UniqueType]
    # @return [ComplexType]
    def transform new_name = nil, &transform_type
      if new_name&.start_with?('::')
        raise "Please remove leading :: and set rooted with recreate() instead - #{new_name}"
      end
      ComplexType.new(map { |ut| ut.transform(new_name, &transform_type) })
    end

    def expand named_types
      ComplexType.new(map { |ut| ut.expand(named_types) })
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
      new_items = items.flat_map do |type|
        next type unless %w[Module Class].include?(type.name)
        next type if type.all_params.empty?

        type.all_params
      end
      ComplexType.new(new_items)
    end

    # every type and subtype in this union have been resolved to be
    # fully qualified
    def all_rooted?
      all?(&:all_rooted?)
    end

    # @param other [ComplexType, UniqueType]
    def erased_version_of? other
      return false if items.length != 1 || other.items.length != 1

      @items.first.erased_version_of?(other.items.first)
    end

    # every top-level type has resolved to be fully qualified; see
    # #all_rooted? to check their subtypes as well
    def rooted?
      all?(&:rooted?)
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
    # the more specific of each compatible pair between the two
    # sides. When neither side is already known to be a subtype of
    # the other but one is positively confirmed to be a mix-in (e.g.
    # a declared class and an unrelated module), both facts are still
    # true at once, so the pair is combined into a
    # ComplexType::UniqueType::Intersection rather than discarded.
    # Everything else - two different concrete classes (impossible;
    # an object has exactly one class), or either side being a
    # namespace we can't positively identify - falls back to the
    # original behavior of dropping the pair; only if every pair is
    # either dropped or empty does the result fall back to UNDEFINED.
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
        narrowing_type.each do |candidate|
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
    # mix-in: any class can pick up any module, so a class-and-module
    # pairing is always plausible. Everything else - two different
    # concrete classes (impossible; an object has exactly one class),
    # or a namespace we have no pin for (synthetic names like
    # `Boolean`, generics, literals, duck types, or simply unresolved)
    # - defaults to false, preserving the original drop-the-pair
    # behavior. This is deliberately conservative: it only recognizes
    # the specific case it was added for rather than guessing about
    # everything narrow_with might be asked to combine.
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
    # @return [Symbol, nil] :class, :module, or nil if unknown
    def namespace_kind api_map, unique_type
      # @type [Pin::Namespace, nil]
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
          types, key_types = parse_type_string(type_string, types, key_types)
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

      # @param strings [Array<String>]
      # @return [ComplexType]
      def try_parse *strings
        parse(*strings)
      rescue ComplexTypeError => e
        Solargraph.logger.info "Error parsing complex type `#{strings.join(', ')}`: #{e.message}"
        ComplexType::UNDEFINED
      end

      private

      # Parses a single type string (one comma-separated slot of a
      # types specifier list) and appends the resulting type(s) to
      # +types+.
      #
      # A top-level `&` (not nested in `<>`, `{}`, or `()`) builds a
      # ComplexType::UniqueType::Intersection instead of a plain
      # UniqueType. This applies equally to ordinary YARD type tags
      # and to RBS-derived tags, since both are parsed here; YARD has
      # no official intersection syntax yet (see
      # https://github.com/lsegal/yard/issues/1644), so this is a
      # Solargraph extension using RBS's `&` convention.
      #
      # @param type_string [String, nil]
      # @param types [Array<ComplexType::UniqueType>]
      # @param key_types [Array<ComplexType::UniqueType>, nil]
      # @return [Array(Array<ComplexType::UniqueType>, Array<ComplexType::UniqueType>, nil)]
      def parse_type_string type_string, types, key_types
        point_stack = 0
        curly_stack = 0
        paren_stack = 0
        bracket_stack = 0
        base = String.new
        subtype_string = String.new
        # conjuncts of an intersection type (`A & B`) seen so far in
        # the current `|`-disjunct of the segment being parsed
        # @type [Array<ComplexType>]
        conjuncts = []
        # disjuncts of a union type (`A | B`) seen so far in the
        # segment currently being parsed
        # @type [Array<ComplexType, ComplexType::UniqueType>]
        disjuncts = []
        # @param char [String]
        type_string&.each_char do |char|
          if char == '='
            # raise ComplexTypeError, "Invalid = in type #{type_string}" unless curly_stack > 0
          elsif char == '<'
            point_stack += 1
          elsif char == '>'
            if subtype_string.end_with?('=') && curly_stack.positive?
              subtype_string += char
            elsif base.end_with?('=')
              raise ComplexTypeError, 'Invalid hash thing' unless key_types.nil?
              key_types = close_key_types(base, subtype_string, conjuncts, disjuncts, types)
              types = []
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
            curly_stack = close_bracket(curly_stack, subtype_string, char, type_string)
            next
          elsif char == '('
            paren_stack += 1
          elsif char == ')'
            paren_stack = close_bracket(paren_stack, subtype_string, char, type_string)
            next
          elsif char == '[' &&
                (bracket_stack.positive? ||
                 (base.strip.empty? && point_stack.zero? && curly_stack.zero? && paren_stack.zero?))
            # Only a fresh atom (blank base, not already nested in
            # <>/{}/()) can start a `[...]` group - matching
            # finish_atom's own precondition. Otherwise `[` is just an
            # ordinary character, e.g. part of a quoted string literal
            # type like `"[]"`, which has no concept of grouping.
            bracket_stack += 1
          elsif char == ']' && bracket_stack.positive?
            bracket_stack = close_bracket(bracket_stack, subtype_string, char, type_string)
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
        if point_stack != 0 || curly_stack != 0 || paren_stack != 0 || bracket_stack != 0
          raise ComplexTypeError,
                "Unclosed subtype in #{type_string}"
        end
        disjuncts.push close_intersection(conjuncts, finish_atom(base, subtype_string))
        types.push close_disjunction(disjuncts)
        [types, key_types]
      end

      # Decrements the stack counter for a closing `}`/`)`/`]` and
      # appends it to the pending subtype substring.
      #
      # @param stack [Integer]
      # @param subtype_string [String]
      # @param char [String]
      # @param type_string [String, nil]
      # @return [Integer] the decremented stack counter
      def close_bracket stack, subtype_string, char, type_string
        stack -= 1
        subtype_string << char
        raise ComplexTypeError, "Invalid close in type #{type_string}" if stack.negative?
        stack
      end

      # Closes the key-list portion of a `Hash{K=>V}` split (the base
      # ending in `=` marks the boundary) and returns the types parsed
      # so far to be stashed as the eventual key_types, leaving
      # conjuncts/disjuncts/base/subtype_string cleared for the value
      # list that follows.
      #
      # @todo this should either expand key_type's type automatically
      #   or complain about not being compatible with key_type's type
      #   in type checking
      #
      # @param base [String]
      # @param subtype_string [String]
      # @param conjuncts [Array<ComplexType>]
      # @param disjuncts [Array<ComplexType, ComplexType::UniqueType>]
      # @param types [Array<ComplexType::UniqueType, ComplexType>]
      # @return [Array<ComplexType::UniqueType, ComplexType>] the key_types
      def close_key_types base, subtype_string, conjuncts, disjuncts, types
        # @sg-ignore Need to add nil check here
        disjuncts.push close_intersection(conjuncts, finish_atom(base[0..-2], subtype_string))
        types.push close_disjunction(disjuncts)
        conjuncts.clear
        disjuncts.clear
        base.clear
        subtype_string.clear
        types
      end

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
      # ends). A bracket group's content is parsed the same way any
      # other parameter substring is - recursively, via
      # ComplexType.parse - and its result substituted directly, since
      # it can itself be a multi-item union (or an intersection).
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
      # in the segment currently being parsed into a single value to
      # push into the enclosing types/subtypes list - a bare type when
      # there was only one (the common case, `|` never used), or a
      # real multi-item ComplexType union otherwise. This is also
      # exactly what a top-level `,` in an already-implicit-union
      # context (Array<...>, Set<...>, hash key/value lists, the
      # top-level types list itself) reduces to, since each of those
      # contexts flattens every comma-separated type into one union
      # regardless of how it's grouped here - so `,` and `|` land on
      # the same result there, matching RBS's own tag design.
      #
      # @param disjuncts [Array<ComplexType, ComplexType::UniqueType>]
      # @return [ComplexType::UniqueType, ComplexType]
      # @sg-ignore #first is only nil for an empty array, and this is
      #   never called with one
      def close_disjunction disjuncts
        return disjuncts.first if disjuncts.length == 1
        ComplexType.new(disjuncts)
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
