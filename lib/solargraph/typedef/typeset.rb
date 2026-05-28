# frozen_string_literal: true

module Solargraph
  module Typedef
    class Typeset
      attr_reader :types

      # @param types [Array<Type>]
      def initialize types
        @types = types
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
