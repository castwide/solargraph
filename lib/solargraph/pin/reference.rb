module Solargraph
  module Pin
    class Reference
      # @return [Source::Location]
      attr_reader :location

      # @return [String]
      attr_reader :namespace

      # @return [String]
      attr_reader :name

      # @param location [Source::Location]
      # @param namespace [String]
      # @param name [String]
      def initialize location, namespace, name
        @location = location
        @namespace = namespace
        @name = name
      end

      # @return [String]
      def filename
        location.filename
      end
    end
  end
end
