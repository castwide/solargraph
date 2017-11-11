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

      def get_methods namespace:, root:, scope:, with_private: false
        []
      end

      def runtime?
        false
      end
    end
  end
end
