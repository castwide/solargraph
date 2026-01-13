# frozen_string_literal: true

module Solargraph
  class SourceMap
    class Data
      # @param source [Solargraph::Source]
      def initialize source
        @source = source
      end

      # @return [Array<Solargraph::Pin::Base>]
      # @sg-ignore https://github.com/castwide/solargraph/pull/1100
      def pins
        generate
        @pins || []
      end

      # @return [Array<Solargraph::LocalVariable>]
      # @sg-ignore https://github.com/castwide/solargraph/pull/1100
      def locals
        generate
        @locals || []
      end

      private

      # @return [void]
      def generate
        return if @generated

        @generated = true
        @pins, @locals = Mapper.map(@source)
      end
    end
  end
end
