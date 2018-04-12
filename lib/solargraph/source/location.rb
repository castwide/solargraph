module Solargraph
  class Source
    class Location
      attr_reader :filename
      attr_reader :range

      def initialize filename, range
        @filename = filename
        @range = range
      end
    end
  end
end
