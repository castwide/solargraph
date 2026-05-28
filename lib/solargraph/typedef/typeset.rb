# frozen_string_literal: true

module Solargraph
  module Typedef
    class Typeset
      attr_reader :types

      # @param types [Array<Type>]
      def initialize types
        @types = types
      end

      # @param named_values [Hash]
      def expand(named_values)
        Typeset.new(types.map { |type| type.expand(named_values) })
      end

      def resolve_rooted(api_map, gates)
        Typeset.new(types.map { |type| type.resolve_rooted(api_map, gates) })
      end

      def generic?
        types.any?(&:generic?)
      end

      # @return [ComplexType]
      def to_complex_type
        ComplexType.new(types.map(&:to_complex_type))
      end

      def to_s
        types.join(', ')
      end

      # @param [ComplexType]
      # @return [self]
      def self.from_complex_type complex_type
        new(complex_type.to_typedef_types)
      end
    end
  end
end
