module Solargraph
  class Source
    class Range
      # @return [Position]
      attr_reader :start

      # @return [Position]
      attr_reader :ending

      # @param start [Position]
      # @param ending [Position]
      def initialize start, ending
        @start = start
        @ending = ending
      end

      # Get a hash of the range. This representation is suitable for use in
      # the language server protocol.
      #
      # @return [Hash<Symbol, Position>]
      def to_hash
        {
          start: start.to_hash,
          end: ending.to_hash
        }
      end

      # True if the specified position is inside the range.
      #
      # @return [Boolean]
      def contain? position
        return false if position.line < start.line
        return false if position.line == start.line and position.character < start.character
        return false if position.line > ending.line
        return false if position.line == ending.line and position.character > ending.character
        true
      end

      # Create a range from a pair of lines and characters.
      #
      # @param l1 [Integer] Starting line
      # @param c1 [Integer] Starting character
      # @param l2 [Integer] Ending line
      # @param c2 [Integer] Ending character
      # @return [Range]
      def self.from_to l1, c1, l2, c2
        Range.new(Position.new(l1, c1), Position.new(l2, c2))
      end

      def == other
        return false unless other.is_a?(Range)
        start == other.start and ending == other.ending
      end
    end
  end
end
