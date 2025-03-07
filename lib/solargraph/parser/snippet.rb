module Solargraph
  module Parser
    class Snippet
      # @return [Range]
      attr_reader :range
      # @return [String]
      attr_reader :text

      def initialize range, text
        @range = range
        @text = text
      end
    end
  end
end
