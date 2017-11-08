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

      def start
        raise "#{self.class} needs to implement the start method"
      end

      def stop
        raise "#{self.class} needs to implement the stop method"
      end

      def get_methods namespace:, root:, scope:, with_private: false
        raise "#{self.class} needs to implement the get_methods method"
      end

      protected

      def respond_ok data
        Solargraph::Plugin::Response.new('ok', data)
      end

      def respond_err exception
        Solargraph::Plugin::Response.new('err', [], exception.message)
      end
    end
  end
end
