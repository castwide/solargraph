module Solargraph
  module Pin
    class Reference
      # @return [Source::Location]
      attr_reader :location

      # @return [String]
      attr_reader :namespace

      # @return [String]
      attr_reader :name

      def initialize location, namespace, name
        @location = location
        @namespace = namespace
        @name = name
      end

      # @todo Deprecaate
      def resolve api_map
      end

      def filename
        location.filename
      end
    end
  end
end
