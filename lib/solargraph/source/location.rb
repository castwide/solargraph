module Solargraph
  class Source
    class Location
      # @return [String]
      attr_reader :filename

      # @return [Solargraph::Source::Range]
      attr_reader :range

      # @param filename [String]
      # @param range [Solargraph::Source::Range]
      def initialize filename, range
        @filename = filename
        @range = range
      end

      def == other
        return false unless other.is_a?(Location)
        filename == other.filename and range == other.range
      end
    end
  end
end
