module Solargraph
  class SourceMap
    class Region
      # @return [String]
      attr_reader :filename

      # @return [String]
      attr_reader :namespace

      # @param filename [String]
      # @param namespace [String]
      def initialize filename, namespace
        @filename = filename
        @namespace = namespace
      end
    end
  end
end
