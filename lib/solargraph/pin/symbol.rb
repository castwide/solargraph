module Solargraph
  module Pin
    class Symbol
      attr_reader :location

      attr_reader :name

      def initialize location, name
        @name = name
        @location = location
      end

      def filename
        location.filename
      end

      def kind
        Pin::SYMBOL
      end
    end
  end
end
