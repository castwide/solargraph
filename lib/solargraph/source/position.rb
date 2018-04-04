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

      # Get a hash of the position. This representation is suitable for use in
      # the language server protocol.
      #
      def to_hash
        {
          line: line,
          character: character
        }
      end
    end
  end
end
