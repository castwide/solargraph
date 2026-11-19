# frozen_string_literal: true

module Solargraph
  class SourceMap
    class Data
      # @param source [Solargraph::Source]
      def initialize source
        @source = source
      end

      # @sg-ignore Translate to something flow sensitive typing understands
      # @return [Array<Solargraph::Pin::Base>]
      # @sg-ignore https://github.com/castwide/solargraph/pull/1100
      def pins
        generate
        @pins || []
      end

      # @sg-ignore Translate to something flow sensitive typing understands
      # @return [Array<Solargraph::Pin::ExpressionType>] the file's variables and expression narrowings
      def expression_types
        generate
        @expression_types || []
      end

      private

      # @return [void]
      def generate
        return if @generated

        @generated = true
        @pins, @expression_types = Mapper.map(@source)
      end
    end
  end
end
