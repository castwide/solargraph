module Solargraph
  module Plugin
    class Runtime < Base
      def start
      end

      def stop
      end

      def runtime?
        true
      end

      def get_methods namespace:, root:, scope:, with_private: false
        raise "#{self.class} needs to implement the get_methods method"
      end
    end
  end
end
