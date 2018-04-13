module Solargraph
  module Pin
    class Symbol < Base
      attr_reader :location

      attr_reader :name

      def initialize location, name
        @name = name
        @location = location
      end

      def filename
        location.filename
      end
    end
  end
end
