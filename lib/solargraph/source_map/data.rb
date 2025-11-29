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
      def pins
        generate
        @pins || []
      end

      # @sg-ignore Translate to something flow sensitive typing understands
      # @return [Array<Solargraph::Pin::LocalVariable>]
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
