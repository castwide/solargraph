module Solargraph
  module Parser
    class Snippet
      # @return [Solargraph::Range]
      attr_reader :range
      # @return [String]
      attr_reader :text

      # @param range [Solargraph::Range]
      # @param text [String]
      def initialize range, text
        @range = range
        @text = text
      end
    end
  end
end
