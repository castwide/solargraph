# frozen_string_literal: true

module Solargraph
  class SourceMap
    class Call
      attr_reader :source_map, :chain, :closure

      # @param source_map [SourceMap]
      # @param chain [Source::Chain]
      # @param closure [Pin::Closure]
      def initialize source_map, chain, closure
        @source_map = source_map
        @chain = chain
        @closure = closure
      end
    end
  end
end
