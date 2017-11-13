module Solargraph
  module Plugin
    class Base
      # @return [Solargraph::ApiMap]
      attr_reader :api_map

      def initialize api_map
        @api_map = api_map
        post_initialize
      end

      def post_initialize
      end

      # @return [Array<String>]
      def get_methods namespace:, root:, scope:, with_private: false
        []
      end

      # @return [Array<String>]
      def get_constants namespace, root
        []
      end

      # @return [String]
      def get_fqns namespace, root
        nil
      end

      # @return [Boolean]
      def refresh
        false
      end

      # @return [Boolean]
      def runtime?
        false
      end
    end
  end
end
