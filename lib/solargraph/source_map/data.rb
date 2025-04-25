# frozen_string_literal: true

module Solargraph
  class SourceMap
    class Data
      def initialize source
        @source = source
      end

      def pins
        generate
        @pins || []
      end

      def locals
        generate
        @locals || []
      end

      private

      def generate
        return if @generated

        @generated = true
        @pins, @locals = Mapper.map(@source)
      end
    end
  end
end
