module Solargraph
  module Plugin
    class Base

      def initialize workspace
        # @!attribute [r] workspace
        #   @return [String]
        define_singleton_method(:workspace) { workspace }
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
    end
  end
end
