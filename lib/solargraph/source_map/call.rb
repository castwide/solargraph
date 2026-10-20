# frozen_string_literal: true

module Solargraph
  class SourceMap
    class Call
      attr_reader :chain, :closure

      # @param chain [Source::Chain]
      # @param closure [Pin::Closure]
      def initialize chain, closure
        @chain = chain
        @closure = closure
      end
    end
  end
end
