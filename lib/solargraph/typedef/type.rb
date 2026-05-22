# frozen_string_literal: true

module Solargraph
  module Typedef
    class Type
      attr_reader :base

      attr_reader :params

      # @param base [String, Path, Token]
      # @param params [Array<String, Path, Token>]
      def initialize base, *params
        @base = Typedef.tokenize(base)
        @params = params.map { |par| Typedef.tokenize(par) }
      end

      def resolved?
        base.resolved? && params.all?(&:resolved?)
      end

      def to_s
        "#{base}#{params_to_s}"
      end

      # @param [Array<ComplexType>]
      # @retunrn [Array<Type>]
      def self.from_complex_type complex_type
        complex_type.to_typedef_types
      end

      private

      def params_to_s
        return "" if @params.empty?
        "[#{params.join(', ')}]"
      end
    end
  end
end
