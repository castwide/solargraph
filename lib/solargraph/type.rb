# frozen_string_literal: true

module Solargraph
  # The contract every type class implements: ComplexType (a union) and
  # ComplexType::UniqueType (one member of it). Code that accepts or
  # returns "a type, whichever kind" writes [Type].
  #
  # spec/type_contract_spec.rb checks that each subclass defines every
  # method declared here, and that every public method all subclasses
  # share is declared here.
  #
  # @abstract Every method below is a declaration with no implementation;
  #   subclasses must define each one.
  # rubocop:disable Lint/EmptyClass
  class Type
    # rubocop:enable Lint/EmptyClass

    # @!method ==(other)
    #   @param other [Object]
    #   @return [Boolean]

    # @!method all?(&block)
    #   @yieldparam [ComplexType::UniqueType]
    #   @yieldreturn [Boolean]
    #   @return [Boolean]

    # @!method all_params
    #   @return [Array<ComplexType>]

    # @!method all_rooted?
    #   Whether every type and subtype is fully qualified.
    #   @return [Boolean]

    # @!method any?(&block)
    #   @yieldparam [ComplexType::UniqueType]
    #   @yieldreturn [Boolean]
    #   @return [Boolean]

    # @!method conforms_to?(api_map, expected, situation, rules = [], variance: erased_variance(situation))
    #   @param api_map [ApiMap]
    #   @param expected [Type]
    #   @param situation [:method_call, :return_type, :assignment]
    #   @param rules [Array<:allow_subtype_skew, :allow_empty_params, :allow_reverse_match, :allow_any_match, :allow_undefined, :allow_unresolved_generic, :allow_unmatched_interface>]
    #   @param variance [:invariant, :covariant, :contravariant]
    #   @return [Boolean]

    # @!method defined?
    #   @return [Boolean]

    # @!method desc
    #   @return [String]

    # @!method downcast_to_literal_if_possible
    #   @return [Type]

    # @!method duck_type?
    #   @return [Boolean]

    # @!method each(&block)
    #   @yieldparam [ComplexType::UniqueType]
    #   @return [Enumerable<ComplexType::UniqueType>]

    # @!method each_unique_type(&block)
    #   @yieldparam [ComplexType::UniqueType]
    #   @return [void]
    #   @overload each_unique_type()
    #     @return [Enumerator<ComplexType::UniqueType>]

    # @!method eql?(other)
    #   @param other [Object]
    #   @return [Boolean]

    # @!method erased_variance(situation = :method_call)
    #   Variance of the type ignoring any type parameters.
    #   @param situation [:method_call, :return_type, :assignment]
    #   @return [Symbol]

    # @!method erased_version_of?(other)
    #   @param other [Type]
    #   @return [Boolean]

    # @!method exclude(exclude_types, api_map)
    #   @param exclude_types [ComplexType, nil]
    #   @param api_map [ApiMap]
    #   @return [Type]

    # @!method expand(named_types)
    #   @param named_types [Hash{String => Type}]
    #   @return [Type]

    # @!method force_rooted
    #   @return [self]

    # @!method generic?
    #   @return [Boolean]

    # @!method hash
    #   @return [Integer]

    # @!method items
    #   @return [Array<ComplexType::UniqueType>]

    # @!method literal?
    #   @return [Boolean]

    # @!method map(&block)
    #   @yieldparam [ComplexType::UniqueType]
    #   @return [Array]

    # @!method namespace
    #   @return [String]

    # @!method namespace_type
    #   @return [Type]

    # @!method nil_type?
    #   @return [Boolean]

    # @!method nullable?
    #   Whether nil is a possible value.
    #   @return [Boolean]

    # @!method qualify(api_map, *gates)
    #   Fully qualify this type's namespaces.
    #   @param api_map [ApiMap]
    #   @param gates [Array<String>] The namespaces from which to resolve names
    #   @return [Type]

    # @!method recreate(new_name: nil, make_rooted: nil, new_key_types: nil, new_subtypes: nil)
    #   @param new_name [String, nil]
    #   @param make_rooted [Boolean, nil]
    #   @param new_key_types [Array<ComplexType>, nil]
    #   @param new_subtypes [Array<ComplexType>, nil]
    #   @return [self]

    # @!method reduce_class_type
    #   @return [ComplexType]

    # @!method resolve_generics(definitions, context_type)
    #   @param definitions [Pin::Namespace, Pin::Method]
    #   @param context_type [ComplexType]
    #   @return [Type]

    # @!method resolve_generics_from_context(generics_to_resolve, context_type, resolved_generic_values: {})
    #   @param generics_to_resolve [Enumerable<String>]
    #   @param context_type [Type, nil]
    #   @param resolved_generic_values [Hash{String => Type}] Added to as types are encountered or resolved
    #   @return [Type]

    # @!method rooted?
    #   Whether every top-level type is fully qualified.
    #   @return [Boolean]

    # @!method rooted_namespace
    #   @return [String]

    # @!method rooted_tag
    #   @return [String]

    # @!method rooted_tags
    #   @return [String]

    # @!method scope
    #   @return [::Symbol] :class or :instance

    # @!method self_to_type(dst)
    #   @param dst [Type]
    #   @return [Type]

    # @!method selfy?
    #   @return [Boolean]

    # @!method simplify_literals
    #   @return [self]

    # @!method tag
    #   @return [String]

    # @!method tags
    #   @return [String]

    # @!method to_a
    #   @return [Array<ComplexType::UniqueType>]

    # @!method to_rbs
    #   @return [String]

    # @!method to_s
    #   @return [String]

    # @!method transform(new_name = nil, &transform_type)
    #   @param new_name [String, nil]
    #   @yieldparam t [ComplexType::UniqueType]
    #   @yieldreturn [ComplexType::UniqueType]
    #   @return [Type]

    # @!method undefined?
    #   @return [Boolean]

    # @!method value_types
    #   @return [Array<ComplexType>]

    # @!method void?
    #   @return [Boolean]

    # @!method without_nil
    #   @return [Type]
  end
end
