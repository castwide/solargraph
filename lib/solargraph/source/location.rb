module Solargraph
  class Source
    class Location
      # @return [String]
      attr_reader :filename

      # @return [Solargraph::Source::Range]
      attr_reader :range

      def initialize filename, range
        @filename = filename
        @range = range
      end
    end
  end
end
