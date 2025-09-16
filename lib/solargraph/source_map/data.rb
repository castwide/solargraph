# frozen_string_literal: true

module Solargraph
  class SourceMap
    class Data
      # @param source [Solargraph::Source]
      def initialize source
        @source = source
        # @type [Array<Solargraph::Pin::Base>, nil]
        @pins = nil
        # @return [Array<Solargraph::Pin::LocalVariable>, nil]
        @locals = nil
      end

      # @sg-ignore Need better || handling on ivars
      # @return [Array<Solargraph::Pin::Base>]
      def pins
        generate
        # @type [Array<Solargraph::Pin::Base>]
        empty_pins = []
        @pins || empty_pins
      end

      # @sg-ignore Need better || handling on ivars
      # @return [Array<Solargraph::Pin::LocalVariable>]
      def locals
        generate
        # @type [Array<Pin::LocalVariable>]
        empty_locals = []
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
