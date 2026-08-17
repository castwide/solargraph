# frozen_string_literal: true

module Solargraph
  class ComplexType
    class UniqueType
      # A single unique type representing the intersection of two or
      # more conjunct types, e.g., the RBS type `A & B`.
      #
      # Unlike ComplexType's comma-separated items (a union, where any
      # one member describes the value), every conjunct must describe
      # the value independently, so the subtyping rules are a union's
      # mirror image: A & B <: A and A & B <: B (<: means "is a
      # subtype of"), but a value satisfies A & B only if it satisfies
      # every conjunct.
      #
      # Each conjunct is a full ComplexType, not a plain UniqueType, as
      # RBS allows a union as one member of an intersection
      # (`(A | B) & C`) - and so a conjunct may itself be an
      # Intersection.
      #
      # `A & B` parses the same from plain YARD type tags as from
      # inline RBS signatures, since both funnel through
      # ComplexType.parse. YARD has no official intersection syntax
      # yet; `&` is Solargraph's extension pending upstream guidance.
      #
      # @see https://en.wikipedia.org/wiki/Intersection_type
      # @see https://github.com/ruby/rbs/blob/master/docs/syntax.md#intersection-type
      # @see https://github.com/lsegal/yard/issues/1644
      class Intersection < UniqueType
        # @return [Array<ComplexType>]
        attr_reader :conjuncts

        # @param conjuncts [Array<ComplexType>]
        def initialize conjuncts
          @conjuncts = conjuncts
          super(intersection_tag(:tags), rooted: true)
        end

        # @return [String]
        def tag
          @tag ||= intersection_tag(:tags)
        end

        # @return [String]
        def rooted_tag
          @rooted_tag ||= intersection_tag(:rooted_tags)
        end

        # @return [String]
        def to_rbs
          conjuncts.map(&:to_rbs).join(' & ')
        end

        # @return [String]
        def namespace
          conjuncts.fetch(0).namespace
        end

        # @return [::Symbol]
        def scope
          conjuncts.fetch(0).scope
        end

        def generic?
          conjuncts.any?(&:generic?)
        end

        def rooted?
          conjuncts.all?(&:rooted?)
        end

        def all_rooted?
          conjuncts.all?(&:all_rooted?)
        end

        def duck_type?
          false
        end

        def interface?
          false
        end

        # @yieldparam [UniqueType]
        # @return [void]
        # @overload each_unique_type()
        #   @return [Enumerator<UniqueType>]
        def each_unique_type &block
          return enum_for(__method__) unless block_given?
          conjuncts.each { |conjunct| conjunct.each_unique_type(&block) }
        end

        # An intersection can be assigned wherever any one of its
        # conjuncts would be accepted (A & B <: A, A & B <: B). Each
        # conjunct is checked as a full ComplexType, so a conjunct
        # that's itself a union (from `(A | B) & C`) gets real union
        # semantics (every member of that union must conform).
        #
        # When expected is *also* an intersection, the rule instead is
        # that every conjunct of the expected side must be satisfied by
        # *some* conjunct of this one, not necessarily the same one each
        # time - handled separately below.
        #
        # A union on the expected side is tried one alternative at a
        # time first, so that an intersection buried in a union is
        # still compared as an intersection. Checking the conjuncts
        # against the whole union instead asks a single conjunct to
        # carry the match on its own, which `A & false` cannot do
        # against a union that contains `A & false` itself.
        #
        # @param api_map [ApiMap]
        # @param expected [ComplexType, ComplexType::UniqueType]
        # @param situation [:method_call, :assignment, :return_type]
        # @param rules [Array<:allow_subtype_skew, :allow_empty_params, :allow_reverse_match, :allow_any_match, :allow_undefined, :allow_unresolved_generic>]
        # @param variance [:invariant, :covariant, :contravariant]
        # @return [Boolean]
        def conforms_to? api_map, expected, situation, rules = [],
                         variance: erased_variance(situation)
          return true if any_union_alternative_conforms?(api_map, expected, situation, rules, variance)

          expected_intersection = sole_intersection(expected)
          if expected_intersection
            return expected_intersection.conjuncts.all? do |expected_conjunct|
              conjuncts.any? do |conjunct|
                conjunct.conforms_to?(api_map, expected_conjunct, situation, rules, variance: variance)
              end
            end
          end
          conjuncts.any? do |conjunct|
            conjunct.conforms_to?(api_map, expected, situation, rules, variance: variance)
          end
        end

        # Every conjunct resolves against the same context, sharing
        # resolved_generic_values - resolved left to right, so an
        # earlier conjunct won't see a generic only a later one binds.
        #
        # @param generics_to_resolve [Enumerable<String>]
        # @param context_type [ComplexType, UniqueType, nil]
        # @param resolved_generic_values [Hash{String => ComplexType, UniqueType}]
        # @return [Intersection]
        def resolve_generics_from_context generics_to_resolve, context_type, resolved_generic_values: {}
          Intersection.new(conjuncts.map do |conjunct|
            conjunct.resolve_generics_from_context(generics_to_resolve, context_type,
                                                   resolved_generic_values: resolved_generic_values)
          end)
        end

        # Applies the transformation to each conjunct independently
        # and rebuilds the intersection from the results.
        #
        # new_name is not passed down to the conjuncts. An
        # intersection's own `name` is the synthetic `"A & B"` string
        # built in #initialize, not a namespace; giving that to each
        # conjunct renames `Hash{"a" => Float}` to
        # `Hash{"a" => Float} & Hash{"b" => Float}{"a" => Float}`,
        # which no longer parses. Each conjunct keeps its own name,
        # which is the only rename that means anything here.
        #
        # @param _new_name [String, nil] ignored - see above
        # @yieldparam t [UniqueType]
        # @yieldreturn [UniqueType]
        # @return [self]
        def transform _new_name = nil, &transform_type
          Intersection.new(conjuncts.map { |conjunct| conjunct.transform(&transform_type) })
        end

        # @return [self]
        def erase_parameters
          self
        end

        private

        # Renders conjuncts as a tag, bracketing multi-item ones since
        # `&` binds tighter than `,`/`|` (`[A|B] & C`, not `A, B & C`).
        #
        # @param tags_method [:tags, :rooted_tags]
        # @return [String]
        def intersection_tag tags_method
          conjuncts.map do |conjunct|
            tags = conjunct.send(tags_method)
            conjunct.items.length > 1 ? "[#{tags}]" : tags
          end.join(' & ')
        end

        # True when expected is a union and this intersection conforms
        # to one of its alternatives taken on its own.
        #
        # @param api_map [ApiMap]
        # @param expected [ComplexType, ComplexType::UniqueType]
        # @param situation [:method_call, :assignment, :return_type]
        # @param rules [Array<Symbol>]
        # @param variance [:invariant, :covariant, :contravariant]
        # @return [Boolean]
        def any_union_alternative_conforms? api_map, expected, situation, rules, variance
          return false unless expected.is_a?(ComplexType) && expected.length > 1

          expected.items.any? do |item|
            conforms_to?(api_map, ComplexType.new([item]), situation, rules, variance: variance)
          end
        end

        # Returns expected itself (or its one item) when it's an Intersection, else nil.
        #
        # @param expected [ComplexType, ComplexType::UniqueType]
        # @return [Intersection, nil]
        def sole_intersection expected
          return expected if expected.is_a?(Intersection)
          return expected.first if expected.is_a?(ComplexType) && expected.length == 1 && expected.first.is_a?(Intersection)
          nil
        end
      end
    end
  end
end
