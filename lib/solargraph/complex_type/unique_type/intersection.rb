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
        # @return [Array<UniqueType, Intersection, ComplexType>]
        attr_reader :conjuncts

        # @param conjuncts [Array<UniqueType, Intersection, ComplexType>]
        def initialize conjuncts
          @conjuncts = conjuncts
          super(intersection_tag(:tags), rooted: conjuncts.all?(&:rooted?))
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
        def tags
          tag
        end

        # @return [String]
        def rooted_tags
          rooted_tag
        end

        # @return [String]
        def to_s
          tags
        end

        # @return [String]
        def to_rbs
          conjuncts.map(&:to_rbs).join(' & ')
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        # @return [String]
        def namespace
          raise NotImplementedError, "Intersection #{tag} has no single namespace - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        # @return [::Symbol]
        def scope
          raise NotImplementedError, "Intersection #{tag} has no single scope - resolve each conjunct instead"
        end

        # Pins from the conjuncts defining the method - one is enough -
        # narrowed by the block to those the caller can dispatch to.
        #
        # @param word [String]
        # @param api_map [ApiMap]
        # @yieldparam conjuncts [::Array<ComplexType>]
        # @yieldreturn [::Array<ComplexType>]
        # @return [::Array<Pin::Base>, nil] nil when no conjunct defines it
        def method_stack_pins word, api_map, &narrow_conjuncts
          candidates = block_given? ? yield(conjuncts) : conjuncts
          resolved = candidates.filter_map do |conjunct|
            pins = conjunct.method_stack_pins(word, api_map, &narrow_conjuncts)
            pins.empty? ? nil : pins
          end
          return nil if resolved.empty?

          # @param p [Pin::Base]
          resolved.flatten.uniq { |p| [p.path, p.return_type.tag] }
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

        # @return [Boolean]
        def void?
          conjuncts.all?(&:void?)
        end

        # @return [Boolean]
        def undefined?
          conjuncts.all?(&:undefined?)
        end

        # @return [Boolean]
        def defined?
          conjuncts.any?(&:defined?)
        end

        # @return [Boolean]
        def nil_type?
          conjuncts.all?(&:nil_type?)
        end

        # @return [Boolean]
        def selfy?
          conjuncts.any?(&:selfy?)
        end

        # A value of the intersection satisfies every conjunct, so one
        # literal conjunct fixes it to that literal value.
        #
        # @return [Boolean]
        def literal?
          conjuncts.any?(&:literal?)
        end

        # True when any conjunct gathers its parameters as a union, since
        # the value is all of them at once. A conjunct is a ComplexType,
        # which has no #implicit_union?, so its members answer instead.
        #
        # @return [Boolean]
        def implicit_union?
          each_unique_type.any?(&:implicit_union?)
        end

        # @param other [Object]
        # @return [Boolean]
        def eql? other
          # @sg-ignore flow sensitive typing should support .class == .class
          self.class == other.class && sorted_conjuncts == other.sorted_conjuncts
        end

        # @return [Integer]
        def hash
          [self.class, sorted_conjuncts].hash
        end

        # @yieldparam [UniqueType]
        # @return [void]
        # @overload each_unique_type()
        #   @return [Enumerator<UniqueType>]
        def each_unique_type &block
          return enum_for(__method__) unless block_given?
          conjuncts.each { |conjunct| conjunct.each_unique_type(&block) }
        end

        # Substituting one type for another where this one is expected
        # is safe only where it is safe for every conjunct, so the
        # variance is whatever the conjuncts agree on - and invariant
        # when they disagree, since no one direction then holds for all.
        #
        # @param situation [:method_call, :return_type, :assignment]
        # @return [:invariant, :covariant, :contravariant]
        def erased_variance situation = :method_call
          variances = conjuncts.map { |conjunct| conjunct.erased_variance(situation) }.uniq
          variances.length == 1 ? variances.fetch(0) : :invariant
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
          expected.satisfied_by?(self, api_map, situation, rules, variance: variance)
        end

        # Whether this intersection conforms to a single named
        # expectation: one conjunct carrying it is enough, since the
        # value is all of them at once.
        #
        # @param expected [ComplexType::UniqueType]
        # @param api_map [ApiMap]
        # @param situation [:method_call, :assignment, :return_type]
        # @param rules [Array<Symbol>]
        # @param variance [:invariant, :covariant, :contravariant]
        # @return [Boolean]
        def conforms_to_unique? expected, api_map, situation, rules = [],
                                variance: erased_variance(situation)
          conjuncts.any? do |conjunct|
            conjunct.conforms_to_unique?(expected, api_map, situation, rules, variance: variance)
          end
        end

        # What an inferred type must do to satisfy this intersection:
        # conform to every conjunct, since A & B <: A and A & B <: B.
        #
        # @param inferred [ComplexType, ComplexType::UniqueType]
        # @param api_map [ApiMap]
        # @param situation [:method_call, :assignment, :return_type]
        # @param rules [Array<Symbol>]
        # @param variance [:invariant, :covariant, :contravariant]
        # @return [Boolean]
        def satisfied_by? inferred, api_map, situation, rules = [],
                          variance: inferred.erased_variance(situation)
          conjuncts.all? do |conjunct|
            inferred.conforms_to?(api_map, conjunct, situation, rules, variance: variance)
          end
        end

        # An intersection has no single namespace, so each conjunct is
        # qualified on its own; a conjunct the block cannot resolve
        # leaves the whole type unresolvable.
        #
        # @yieldparam named_type [ComplexType::UniqueType]
        # @yieldreturn [ComplexType::UniqueType, nil]
        # @return [Intersection, nil]
        def qualify_parts &block
          parts = conjuncts.map { |conjunct| conjunct.qualify_parts(&block) }
          Intersection.new(parts) unless parts.any?(&:nil?)
        end

        # The methods reachable on a value of this intersection: the value
        # is every conjunct at once, so it offers whatever any conjunct
        # offers.  #tag names the whole compound type, which is not a
        # namespace, so this cannot go through UniqueType.
        #
        # @param api_map [ApiMap]
        # @param context [String] Fully qualified namespace the type is referenced from
        # @param internal [Boolean] True to include private methods
        # @return [Array<Pin::Base>]
        def candidate_methods_from api_map, context, internal
          conjuncts.flat_map { |conjunct| conjunct.candidate_methods_from(api_map, context, internal) }
                   .uniq
        end

        # Whether any conjunct provides +quack+: the value is all of them
        # at once, so one is enough.  #namespace and #scope report only
        # the first conjunct, which is why this cannot use them.
        #
        # @param api_map [ApiMap]
        # @param quack [String]
        # @return [Boolean]
        def provides_duck_method? api_map, quack
          conjuncts.any? { |conjunct| conjunct.provides_duck_method?(api_map, quack) }
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

        # Each conjunct probes the same definitions and receiver, as in
        # #resolve_generics_from_context above.
        #
        # @param definitions [Pin::Namespace, Pin::Method] The module/class/method which uses generic types
        # @param context_type [ComplexType] The receiver type
        # @return [Intersection]
        def resolve_generics definitions, context_type
          Intersection.new(conjuncts.map { |conjunct| conjunct.resolve_generics(definitions, context_type) })
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

        # @param api_map [ApiMap]
        # @param gates [Array<String>]
        # @return [Intersection]
        def unalias_and_qualify api_map, *gates
          Intersection.new(conjuncts.map { |conjunct| conjunct.unalias_and_qualify(api_map, *gates) })
        end

        # @return [self]
        def erase_parameters
          self
        end

        # Conjuncts are not a union, so nothing moves at this level; a
        # conjunct that is one reorders its own members.
        #
        # @return [Intersection]
        def order_nil_last
          Intersection.new(conjuncts.map(&:order_nil_last))
        end

        # Reduction distributes over conjuncts: Class<A> & Class<B>
        # describes a value that is both an A and a B. #name is the
        # compound tag rather than "Class", so UniqueType cannot do this.
        #
        # @return [ComplexType]
        def reduce_class_type
          ComplexType.new([Intersection.new(conjuncts.map(&:reduce_class_type))])
        end

        # Unwrapping distributes over conjuncts: a value that is both
        # an Object<A, B> and a C is both an A-or-B and a C. #name is the
        # compound tag rather than "Object", so UniqueType cannot do this.
        #
        # @return [ComplexType]
        def reduce_object
          ComplexType.new([Intersection.new(conjuncts.map(&:reduce_object))])
        end

        # @return [Array<ComplexType::UniqueType>]
        def unioned_items
          [self]
        end

        # Pairs conjunct by conjunct with another intersection and
        # rebuilds one from the results. Any other type has no
        # conjuncts to line up with, so it pairs with the whole.
        #
        # @param other [ComplexType, ComplexType::UniqueType]
        # @yieldparam mine [ComplexType, ComplexType::UniqueType]
        # @yieldparam theirs [ComplexType, ComplexType::UniqueType]
        # @yieldreturn [ComplexType, ComplexType::UniqueType]
        # @return [ComplexType, ComplexType::UniqueType]
        def combine_via other, &block
          return block.call(self, other) unless other.is_a?(Intersection)

          # @param members [Array<ComplexType>]
          gather = ->(members) { members.length == 1 ? members.fetch(0) : Intersection.new(members) }
          results = TypeMethods.combine_members(conjuncts, other.conjuncts, gather, &block)
          Intersection.new(results.map { |type| ComplexType.new([type]) })
        end

        # Unanswerable for an intersection: each would report from @name
        # (the whole compound tag) or from subtype and parameter state an
        # intersection never populates.
        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def rooted_namespace(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def rooted_name(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def can_root_name?(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def key_types(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def subtypes(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def all_params(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def parameters_type(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def namespace_type(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def recreate(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def erased_version_of?(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def value_types(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def parameters?(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def list_parameters?(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def fixed_parameters?(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def hash_parameters?(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def substring(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def rooted_substring(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def generate_substring_from(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def parameters_as_rbs(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def resolve_param_generics_from_context(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def rbs_name(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def non_literal_name(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def determine_non_literal_name(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def nullable?(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def expand(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def without_nil(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def narrow_with(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def erase_generics(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def simplify_literals(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def force_rooted(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def self_to_type(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def exclude(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def desc(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def parameter_variance(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def simplifyable_literal?(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def tuple?(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def downcast_to_literal_if_possible(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def rbs_union(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        protected

        # The conjunct set #eql? and #hash already answer from, wrapped so
        # Equality#freeze freezes the set and not each conjunct: freezing
        # a conjunct ComplexType freezes the ComplexType class itself,
        # since its own equality_fields lead with self.class.
        #
        # @return [Array<Array<ComplexType>>]
        def equality_fields
          [sorted_conjuncts]
        end

        # Conjunct order is not part of the type. rooted_tags keys the
        # sort rather than tag, which reports only a union conjunct's
        # first member and drops the :: from a rooted one.
        #
        # @return [Array<ComplexType>]
        def sorted_conjuncts
          conjuncts.sort_by(&:rooted_tags)
        end

        private

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def mixin_pairing?(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

        # @sg-ignore https://github.com/castwide/solargraph/pull/1277
        def namespace_kind(*, **, &)
          raise NotImplementedError, "Intersection #{tag} cannot answer ##{__method__} - resolve each conjunct instead"
        end

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
      end
    end
  end
end
