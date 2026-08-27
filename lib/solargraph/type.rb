# frozen_string_literal: true

module Solargraph
  # Shared abstract interface for the composable kinds of type data used
  # throughout Solargraph: a single type token (Typedef::Unique, including
  # its Typedef::Tuple subclass) and a collection of such tokens
  # (Typedef::Typeset, a union). A future third kind (e.g. an
  # intersection) subclasses this and works at every call site already
  # written against it, instead of duck-typing the same method names by
  # convention. Any code that needs to accept or return "a type value,
  # whichever kind" writes [Type], unqualified, from anywhere in the app.
  #
  # Typedef::Path and Typedef::Token sit outside this hierarchy - they're
  # the leaf tokens a Typedef::Unique's base/params are built from, with
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
  #     its union branches (`types`); for a Unique they're `base` and
  #     `params`, but that's an internal detail already folded into a
  #     single fact, so a Unique is one member from this question's
  #     point of view and its `any_generic?`/`all_generic?` coincide.
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
    #   @return [Array<Typedef::Unique>]

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
  end
end
