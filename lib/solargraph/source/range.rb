module Solargraph
  class Source
    class Range
      # @return [Position]
      attr_reader :start

      # @return [Position]
      attr_reader :end

      def initialize start, ending
        @start = start
        @end = ending
      end

      def to_hash
        {
          start: start.to_hash,
          end: self.end.to_hash
        }
      end

      # Create a range from a pair of lines and characters.
      #
      # @return [Position]
      def self.from_to l1, c1, l2, c2
        Range.new(Position.new(l1, c1), Position.new(l2, c2))
      end
    end
  end
end
