module Solargraph
  class Source
    class Location
      attr_reader :filename
      attr_reader :range
    end

    def initialize filename, range
      @filename = filename
      @range = range
    end
  end
end
