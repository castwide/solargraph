# frozen_string_literal: true

module Solargraph
  class SourceMap
    class Call
      # @return [SourceMap]
      attr_reader :source_map

      # @return [Source::Chain]
      attr_reader :chain

      # @return [Pin::Closure, nil]
      attr_reader :closure

      # @param source_map [SourceMap]
      # @param chain [Source::Chain]
      # @param closure [Pin::Closure, nil]
      def initialize source_map, chain, closure
        @source_map = source_map
        @chain = chain
        @closure = closure
      end
    end
  end
end
