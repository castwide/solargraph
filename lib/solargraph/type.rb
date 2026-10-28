# frozen_string_literal: true

module Solargraph
  # Shared abstract interface for the composable kinds of type data used
  # throughout Solargraph: a single type token (Typedef::Concrete, including
  # its Typedef::Tuple subclass) and a collection of such tokens
  # (Typedef::Typeset, itself abstract - Typedef::Union combines its
  # members with OR; a future Typedef::Intersection would combine them
  # with AND). A future kind at either level subclasses the right spot and
  # works at every call site already written against it, instead of
  # duck-typing the same method names by convention. Any code that needs
  # to accept or return "a type value, whichever kind" writes [Type],
  # unqualified, from anywhere in the app.
  #
  # ComplexType (a union) and ComplexType::UniqueType (one member of it)
  # are the implementation lib/ runs on today, so they subclass Type too
  # while callers move to it. spec/type_contract_spec.rb lists, per
  # class, the methods below each implementation does not define yet.
  #
  # Typedef::Path and Typedef::Token sit outside this hierarchy - they're
  # the leaf tokens a Typedef::Concrete's base/params are built from, with
  # their own narrower protocol - but they implement #any_generic? for the
  # same reason: Type's own methods recurse into whatever base/params hold.
  #
  # @abstract Every method below is a stub with no implementation; calling
  #   one directly on Type raises NoMethodError. Subclasses (and only
  #   subclasses) must implement all of them. The four boolean reductions
  #   below are singled out because their aggregation rule is easy to
  #   reinvent inconsistently per subclass if it isn't stated once, here:
  #
  #   - `rooted?`, `resolved?`, `expanded?` are each true only if every
  #     element, recursively, satisfies the check - partial completion
  #     isn't completion, so there is no useful "any" reading.
  #   - `nullable?` is true if any element could be the nil type - a
  #     union that merely allows nil is exactly what callers need to
  #     know, and "all elements are nil" isn't a useful question.
  #   - `any_generic?`/`all_generic?` ask whether any/all of the
  #     receiver's own immediate members contain a generic placeholder
  #     anywhere in their own structure. For a Typeset the members are
  #     its own `types` branches (union members for a Union, and,
  #     eventually, conjuncts for an Intersection); for a Concrete they're
  #     `base` and `params`, but that's an internal detail already folded
  #     into a single fact, so a Concrete is one member from this
  #     question's point of view and its `any_generic?`/`all_generic?`
  #     coincide.
  #     This is a breadth check over immediate members, not a depth
  #     check over nested structure - don't read it the way
  #     ComplexType::UniqueType#all_rooted? reads "all_", which is a
  #     depth check on a different system.
  # rubocop:disable Lint/EmptyClass
  # Documentation-only on purpose: every method below is an abstract
  # stub, not a shared implementation - see the class comment above.
  class Type
    # rubocop:enable Lint/EmptyClass
    # @!method expand(named_values)
    #   Substitute named generic tokens with concrete values throughout
    #   this element's structure.
    #   @param named_values [Hash]
    #   @return [Type]

    # @!method resolve_rooted(api_map, gates)
    #   @param api_map [ApiMap]
    #   @param gates [Array<String>]
    #   @return [Type]

    # @!method extract_generics(other)
    #   Structurally match against another element of the same shape,
    #   collecting generic parameter bindings.
    #   @param other [Type, nil]
    #   @return [Hash]

    # @!method flat_types
    #   @return [Array<Typedef::Concrete>]

    # @!method to_complex_type
    #   @return [ComplexType]

    # @!method to_s
    #   @return [String]

    # @!method to_s_for_complex_type
    #   @return [String]

    # @!method rooted?
    #   @return [Boolean]

    # @!method resolved?
    #   @return [Boolean]

    # @!method expanded?
    #   @return [Boolean]

    # @!method nullable?
    #   @return [Boolean]

    # @!method any_generic?
    #   @return [Boolean]

    # @!method all_generic?
    #   @return [Boolean]

    # @!method undefined?
    #   @return [Boolean]

    # @!method defined?
    #   @return [Boolean]

    # @!method candidate_methods_from(api_map, context, internal)
    #   The methods that might be reachable on a value of this type, from
    #   +context+.
    #   @param api_map [ApiMap]
    #   @param context [String] Fully qualified namespace the type is referenced from
    #   @param internal [Boolean] True to include private methods
    #   @return [Array<Pin::Base>]

    # @!method method_stack_pins(word, api_map)
    #   The pins for calling +word+ on a value of this type, or nil when
    #   the type does not resolve it.
    #   @param word [String]
    #   @param api_map [ApiMap]
    #   @return [Array<Pin::Base>, nil]

    # @!method qualify_parts(&block)
    #   Rebuilds this type with each named part replaced by what the block
    #   returns for it; nil from the block for any part makes the whole
    #   type unresolvable.
    #   @yieldparam named_type [Type]
    #   @yieldreturn [Type, nil]
    #   @return [Type, nil]

    # @!method combine_via(other, &block)
    #   Pairs this type up with +other+ member by member, yields each pair,
    #   and reassembles the results.
    #   @param other [Type]
    #   @yieldparam mine [Type]
    #   @yieldparam theirs [Type]
    #   @yieldreturn [Type]
    #   @return [Type]

    # @!method order_nil_last
    #   This type with any nil members moved to the end, by convention.
    #   @return [Type]

    # @!method ==(other)
    #   @param other [Object]
    #   @return [Boolean]

    # @!method eql?(other)
    #   @param other [Object]
    #   @return [Boolean]

    # @!method hash
    #   @return [Integer]

    # @!method all_rooted?
    #   Whether every type and parameter is fully qualified.
    #   @return [Boolean]

    # @!method conforms_to?(api_map, expected, situation, rules = [], variance: erased_variance(situation))
    #   @param api_map [ApiMap]
    #   @param expected [Type]
    #   @param situation [:method_call, :return_type, :assignment]
    #   @param rules [Array<:allow_subtype_skew, :allow_empty_params, :allow_reverse_match, :allow_any_match, :allow_undefined, :allow_unresolved_generic, :allow_unmatched_interface>]
    #   @param variance [:invariant, :covariant, :contravariant]
    #   @return [Boolean]

    # @!method erased_variance(situation = :method_call)
    #   Variance of the type ignoring any type parameters.
    #   @param situation [:method_call, :return_type, :assignment]
    #   @return [Symbol]

    # @!method erased_version_of?(other)
    #   @param other [Type]
    #   @return [Boolean]

    # @!method nil_type?
    #   @return [Boolean]

    # @!method qualify(api_map, *gates)
    #   Fully qualify this type's namespaces.
    #   @param api_map [ApiMap]
    #   @param gates [Array<String>] The namespaces from which to resolve names
    #   @return [Type]

    # @!method reduce_class_type
    #   The instance type a class-object type describes: Foo for Class<Foo>.
    #   @return [Type]

    # @!method resolve_generics(definitions, context_type)
    #   @param definitions [Pin::Namespace, Pin::Method]
    #   @param context_type [Type]
    #   @return [Type]

    # @!method resolve_generics_from_context(generics_to_resolve, context_type, resolved_generic_values: {})
    #   @param generics_to_resolve [Enumerable<String>]
    #   @param context_type [Type, nil]
    #   @param resolved_generic_values [Hash{String => Type}] Added to as types are encountered or resolved
    #   @return [Type]

    # @!method rooted_tags
    #   @return [String]

    # @!method selfy?
    #   @return [Boolean]

    # @!method tags
    #   @return [String]

    # @!method to_rbs
    #   @return [String]

    # @!method transform(new_name = nil, &transform_type)
    #   @param new_name [String, nil]
    #   @yieldparam t [ComplexType::UniqueType]
    #   @yieldreturn [ComplexType::UniqueType]
    #   @return [Type]

    # @!method void?
    #   @return [Boolean]

    # @!method self_to_type(dst)
    #   This type with self replaced by +dst+.
    #   @param dst [Type]
    #   @return [Type]

    # @!method without_nil
    #   @return [Type]

    # @!method downcast_to_literal_if_possible
    #   @return [Type]
  end
end
