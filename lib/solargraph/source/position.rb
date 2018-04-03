module Solargraph
  class Source
    class Position
      # @return [Integer]
      attr_reader :line

      # @return [Integer]
      attr_reader :character

      def initialize line, character
        @line = line
        @character = character
      end

      def to_hash
        {
          line: line,
          character: character
        }
      end
    end
  end
end
