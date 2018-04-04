module Solargraph
  class Source
    class Range
      # @return [Position]
      attr_reader :start

      # @return [Position]
      attr_reader :end

      # @param start [Position]
      # @param ending [Position]
      def initialize start, ending
        @start = start
        @end = ending
      end

      # Get a hash of the range. This representation is suitable for use in
      # the language server protocol.
      #
      def to_hash
        {
          start: start.to_hash,
          end: self.end.to_hash
        }
      end

      # Create a range from a pair of lines and characters.
      #
      # @param l1 [Integer] Starting line
      # @param c1 [Integer] Starting character
      # @param l2 [Integer] Ending line
      # @param c2 [Integer] Ending character
      # @return [Position]
      def self.from_to l1, c1, l2, c2
        Range.new(Position.new(l1, c1), Position.new(l2, c2))
      end
    end
  end
end
