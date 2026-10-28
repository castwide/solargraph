# frozen_string_literal: true

module Solargraph
  module Typedef
    # Shared base for the composite kinds built out of multiple types
    # combined together - a union (Typedef::Union, "any of these describes
    # the value") or a future intersection (Typedef::Intersection, "all of
    # these describe the value simultaneously" - not yet implemented).
    #
    # Well-formedness of each element (rootedness, resolution, expansion),
    # completeness-of-information (any_generic?/all_generic?), and the
    # structural recursions that walk `types` to build a same-kind result
    # (expand, resolve_rooted, extract_generics, flat_types) all work the
    # same way regardless of how the branches combine, so they live here.
    #
    # How the branches actually combine - nullability, string rendering,
    # conversion to ComplexType (which has no representation for AND at
    # all, only OR) - is exactly what differs between a union and an
    # intersection, so those are abstract stubs a subclass must implement.
    #
    # @abstract nullable?, to_s, to_s_for_complex_type, and to_complex_type
    #   have no shared implementation below; calling one directly on a
    #   Typeset raises NoMethodError. Subclasses must implement all four.
    class Typeset < Type
      # @!method nullable?
      #   @return [Boolean]

      # @!method to_s
      #   @return [String]

      # @!method to_s_for_complex_type
      #   @return [String]

      # @!method to_complex_type
      #   @return [ComplexType]

      # @return [Array<Type>]
      attr_reader :types

      # @param types [Array<Type>]
      def initialize types
        super()
        # @todo Slightly naive reduction of nested same-kind typesets to types
        @types = types.flat_map { |type_or_set| flatten_member(type_or_set) }
        reduce!
      end

      # @param named_values [Hash]
      def expand named_values
        self.class.new(types.map { |type| type.expand(named_values) })
      end

      # Structurally match against another Typeset of the same kind,
      # collecting generic parameter bindings pairwise across `types`.
      # @param typeset [Typeset, nil]
      # @return [Hash]
      def extract_generics typeset
        return {} unless any_generic? && typeset.instance_of?(self.class)
        extracted = {}
        types.each.with_index { |type, idx| extracted.merge! type.extract_generics(typeset.types[idx]) }
        extracted
      end

      # @param api_map [ApiMap]
      # @param gates [Array<String>]
      def resolve_rooted api_map, gates
        self.class.new(types.map { |type| type.resolve_rooted(api_map, gates) })
      end

      # @return [Boolean] true if any member contains a generic
      #   placeholder anywhere in its own structure
      def any_generic?
        types.any?(&:any_generic?)
      end

      # @return [Boolean] true if every member contains a generic
      #   placeholder anywhere in its own structure
      def all_generic?
        types.all?(&:any_generic?)
      end

      def rooted?
        types.all?(&:rooted?)
      end

      def resolved?
        types.all?(&:resolved?)
      end

      def expanded?
        types.all?(&:expanded?)
      end

      def flat_types
        types.flat_map(&:flat_types)
      end

      # Rebuilds this typeset with each named type replaced by what the
      # block returns for it. A block returning nil makes the whole type
      # unresolvable, since a typeset with a missing member is not one.
      #
      # @yieldparam named_type [Concrete]
      # @yieldreturn [Concrete, nil]
      # @return [Typeset, nil]
      def qualify_parts &block
        parts = types.map { |type| type.qualify_parts(&block) }
        self.class.new(parts) unless parts.any?(&:nil?)
      end

      # The methods that might be reachable on a value of this typeset,
      # pooled from its members: a union's value is one of them, and an
      # intersection's value is all of them at once.
      #
      # @param api_map [ApiMap]
      # @param context [String] Fully qualified namespace the type is referenced from
      # @param internal [Boolean] True to include private methods
      # @return [Array<Pin::Base>]
      def candidate_methods_from api_map, context, internal
        types.flat_map { |type| type.candidate_methods_from(api_map, context, internal) }.uniq
      end

      def undefined?
        to_s == 'undefined'
      end

      def defined?
        !undefined?
      end

      private

      def reduce!
        types.uniq!(&:to_s)
      end

      # A nested composite of the same concrete kind flattens into this
      # one - a union nested in a union is still just a union - but a
      # union nested in an intersection must NOT flatten, so the check is
      # against self.class, not against Typeset itself. A same-kind
      # Concrete wrapping (a params-less base) unwraps the same way.
      # @param type_or_set [Type, Array]
      # @return [Type, Array]
      def flatten_member type_or_set
        if type_or_set.instance_of?(self.class)
          # @sg-ignore Unresolved call to types on Solargraph::Type, Array -
          #   instance_of?(self.class) doesn't narrow like is_a?(LiteralClass)
          #   does, since self.class isn't statically known
          type_or_set.types
        elsif type_or_set.is_a?(Concrete) && type_or_set.base.instance_of?(self.class) && type_or_set.params.empty?
          type_or_set.base.types
        else
          type_or_set
        end
      end
    end
  end
end
