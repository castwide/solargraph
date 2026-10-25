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
      items = fold_boolean_cases(ComplexType.flatten_unions(types).uniq(&:rooted_tags))
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
    # @return [Array<Pin::Base>]
    def method_stack_pins word, api_map
      pin_groups = @items.map { |item| item.method_stack_pins(word, api_map) }
      return [] if !api_map.loose_unions && pin_groups.any?(&:nil?)

      # Dedup on path *and* return type: alternatives can share a
      # path (e.g. same generic method on different instantiations).
      # @param p [Pin::Base]
      pin_groups.compact.flatten.uniq { |p| [p.path, p.return_type.rooted_tags] }
    end

    # @param generics_to_resolve [Enumerable<String>]]
    # @param context_type [ComplexType, ComplexType::UniqueType, nil]
    # @param resolved_generic_values [Hash{String => ComplexType}] Added to as types are encountered or resolved
    # @return [self]
    def resolve_generics_from_context generics_to_resolve, context_type, resolved_generic_values: {}
      return self unless any_generic?

      ComplexType.new(@items.map do |unique_type|
        unique_type.resolve_generics_from_context(generics_to_resolve,
                                                  destructure_context_type(unique_type, context_type),
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
      # Check the name before the emptiness guard, so an unknown name
      # reaches super and raises even when there are no members.
      return super unless respond_to_missing?(name)
      return if @items.first.nil?
      @items.first.send(name, *args, &block)
    end

    # @param name [Symbol]
    # @param include_private [Boolean]
    def respond_to_missing? name, include_private = false
      TypeMethods.public_method_defined?(name) || super
    end

    def to_s
      items.map(&:tags).join(', ')
    end

    # @return [String]
    def tags
      items.map(&:tags).join(', ')
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
    # @sg-ignore https://github.com/castwide/solargraph/pull/1397
    def conforms_to? api_map, expected,
                     situation,
                     rules = [],
                     variance: erased_variance(situation)
      expected = expected.downcast_to_literal_if_possible
      inferred = downcast_to_literal_if_possible

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

    # @deprecated A duck expectation routes through
    #   UniqueType#satisfied_by? to #provides_duck_method? instead.
    #
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

    # The methods that might be reachable on a value of this union, from
    # +context+.
    #
    # Pooled, not intersected: a value is only one member, so what is
    # certainly callable is what they all provide.  Both callers want the
    # wider set - completion offers candidates, and the macro test asks
    # whether a pin might belong here.  #method_stack_pins is where a
    # union is strict, under loose_unions.
    #
    # @param api_map [ApiMap]
    # @param context [String] Fully qualified namespace the type is referenced from
    # @param internal [Boolean] True to include private methods
    # @return [Array<Pin::Base>]
    def candidate_methods_from api_map, context, internal
      unioned_items.flat_map { |item| item.candidate_methods_from(api_map, context, internal) }.uniq
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
      items.map(&:rooted_tags).join(', ')
    end

    def selfy?
      @items.any?(&:selfy?)
    end

    # @return [Boolean]
    def any_generic?
      items.any?(&:any_generic?)
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

    # A value of the union may be the void member, so one void member
    # leaves the whole union with nothing usable to say.
    #
    # @return [Boolean]
    def void?
      @items.any?(&:void?)
    end

    # A value of the union may be the member we failed to resolve, so one
    # undefined member makes the whole union undefined.
    #
    # @return [Boolean]
    def undefined?
      @items.any?(&:undefined?)
    end

    # @return [Boolean]
    def defined?
      !undefined?
    end

    # @return [ComplexType]
    def without_nil
      new_items = @items.reject(&:nil_type?)
      return ComplexType::UNDEFINED if new_items.empty?
      ComplexType.new(new_items)
    end

    # A union describes the same type in any order, so this changes only
    # rendering and first-member delegation; partition keeps the rest in place.
    #
    # @return [ComplexType]
    def order_nil_last
      nils, rest = unioned_items.map(&:order_nil_last).partition(&:nil_type?)
      ComplexType.new(rest + nils)
    end

    # @return [Array<ComplexType>]
    def all_params
      @items.first.all_params || []
    end

    # Each member reduces on its own, since a value described by any
    # one of them is described by that member's instance type.
    #
    # @return [ComplexType]
    def reduce_class_type
      ComplexType.new(unioned_items.map(&:reduce_class_type))
    end

    # Each member unwraps on its own, since a value described by any
    # one of them is described by whatever that member unwraps to.
    #
    # @return [ComplexType]
    def reduce_object
      ComplexType.new(unioned_items.map(&:reduce_object))
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

    # @see https://en.wikipedia.org/wiki/Intersection_type
    #
    # @param intersection_type [ComplexType, ComplexType::UniqueType, nil]
    # @param api_map [ApiMap]
    # @return [self, ComplexType::UniqueType]
    def intersect_with intersection_type, api_map
      return self if intersection_type.nil?
      return intersection_type if undefined?
      types = []
      # try to find common types via conformance
      items.each do |ut|
        intersection_type.items.each do |int_type|
          if int_type.conforms_to?(api_map, ut, :assignment)
            types << int_type
          elsif ut.conforms_to?(api_map, int_type, :assignment)
            types << ut
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

    # Boolean is the union of its two cases, so a union offering both
    # is Boolean. Only the set can answer that, no member can, and it
    # answers on the member array because @items is not assigned yet.
    #
    # @param items [Array<UniqueType>]
    # @return [Array<UniqueType>]
    def fold_boolean_cases items
      cases = UniqueType::BOOLEAN_CASES
      return items unless (cases - items).empty?

      [UniqueType::BOOLEAN] + (items - cases)
    end
    private :fold_boolean_cases

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
          base = String.new
          subtype_string = String.new
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
                # types.push ComplexType.new([UniqueType.new(base[0..-2].strip)])
                # @sg-ignore Need to add nil check here
                types.push UniqueType.parse(base[0..-2].strip, subtype_string)
                # @todo this should either expand key_type's type
                #   automatically or complain about not being
                #   compatible with key_type's type in type checking
                key_types = types
                types = []
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
            elsif char == ',' && point_stack.zero? && curly_stack.zero? && paren_stack.zero?
              # types.push ComplexType.new([UniqueType.new(base.strip, subtype_string.strip)])
              types.push UniqueType.parse(base.strip, subtype_string.strip)
              base.clear
              subtype_string.clear
              next
            end
            if point_stack.zero? && curly_stack.zero? && paren_stack.zero?
              base.concat char
            else
              subtype_string.concat char
            end
          end
          if point_stack != 0 || curly_stack != 0 || paren_stack != 0
            raise ComplexTypeError,
                  "Unclosed subtype in #{type_string}"
          end
          # types.push ComplexType.new([UniqueType.new(base, subtype_string)])
          types.push UniqueType.parse(base.strip, subtype_string.strip)
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
        items = flatten_unions(types).uniq(&:rooted_tags)
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

      # The items a union of +types+ would hold: a ComplexType
      # contributes its own items, anything else contributes itself.
      #
      # @param types [Array<ComplexType, ComplexType::UniqueType>]
      # @return [Array<ComplexType::UniqueType>]
      def flatten_unions types
        types.flat_map { |type| type.instance_of?(ComplexType) ? type.unioned_items : [type] }
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

    # Narrows what a generic member binds against: context members this type
    # already matches concretely are dropped. Nothing left over means no value
    # can reach the generic, which is bot.
    #
    # @param unique_type [UniqueType] A member of @items
    # @param context_type [ComplexType, UniqueType, nil]
    # @return [ComplexType, UniqueType, nil]
    def destructure_context_type unique_type, context_type
      return context_type unless unique_type.generic? && context_type.is_a?(ComplexType) && @items.length > 1

      concrete_items = @items.reject(&:generic?)
      return context_type if concrete_items.empty?

      remaining_items = context_type.items.reject { |ct| concrete_items.any? { |ci| ci.name == ct.name } }
      return BOT if remaining_items.empty?

      ComplexType.new(remaining_items)
    end

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
