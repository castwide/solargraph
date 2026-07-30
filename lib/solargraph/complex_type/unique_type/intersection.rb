# frozen_string_literal: true

module Solargraph
  class ComplexType
    class UniqueType
      # A single unique type representing the intersection of two or
      # more conjunct types, e.g., the RBS type `A & B`.
      #
      # Unlike ComplexType's comma-separated items (a union, where any
      # one member describes the value), every conjunct of an
      # Intersection must independently describe the value. That
      # means the subtyping rules are the mirror image of a union's:
      #
      #   A & B <: A
      #   A & B <: B
      #
      # i.e., a value typed as the intersection can be used wherever
      # *any* conjunct is expected, but a value can only be used
      # where the intersection itself is expected if it satisfies
      # *every* conjunct.
      #
      # Each conjunct is a full ComplexType, not a plain UniqueType -
      # the same way UniqueType#subtypes and #key_types already hold
      # ComplexTypes rather than UniqueTypes. RBS itself allows a
      # union as one member of an intersection (`(A | B) & C`), so a
      # conjunct needs to be able to represent more than one
      # alternative; a single type is just the common case of a
      # one-item ComplexType. This also means a conjunct can itself be
      # (or contain) another Intersection, since Intersection is a
      # UniqueType and ComplexType already holds UniqueTypes.
      #
      # `A & B` is parsed the same way from plain YARD type tags
      # (`@param`, `@return`, `@type`, etc.) as it is from inline RBS
      # signatures, since both funnel through ComplexType.parse. YARD
      # itself has no official intersection type syntax yet; `&` is
      # Solargraph's extension pending upstream guidance.
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
          super(conjuncts.map(&:tags).join(' & '), rooted: true)
        end

        # @return [String]
        def tag
          @tag ||= conjuncts.map(&:tags).join(' & ')
        end

        # @return [String]
        def rooted_tag
          @rooted_tag ||= conjuncts.map(&:rooted_tags).join(' & ')
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
        # @param api_map [ApiMap]
        # @param expected [ComplexType, ComplexType::UniqueType]
        # @param situation [:method_call, :assignment, :return_type]
        # @param rules [Array<:allow_subtype_skew, :allow_empty_params, :allow_reverse_match, :allow_any_match, :allow_undefined, :allow_unresolved_generic>]
        # @param variance [:invariant, :covariant, :contravariant]
        # @return [Boolean]
        def conforms_to? api_map, expected, situation, rules = [],
                         variance: erased_variance(situation)
          conjuncts.any? do |conjunct|
            conjunct.conforms_to?(api_map, expected, situation, rules, variance: variance)
          end
        end

        # Applies the transformation to each conjunct independently
        # and rebuilds the intersection from the results.
        #
        # @param new_name [String, nil]
        # @yieldparam t [UniqueType]
        # @yieldreturn [UniqueType]
        # @return [self]
        def transform new_name = nil, &transform_type
          Intersection.new(conjuncts.map { |conjunct| conjunct.transform(new_name, &transform_type) })
        end

        # @return [self]
        def erase_parameters
          self
        end
      end
    end
  end
end
