module Solargraph
  class LiveMap
    class Cache
      def initialize
        @method_cache = {}
        @instance_method_cache = {}
      end

      def get_methods options
        @method_cache[options]
      end

      def set_methods options, values
        @method_cache[options] = values
      end

      def get_instance_methods options
        @instance_method_cache[options]
      end

      def set_instance_methods options, values
        @instance_method_cache[options] = values
      end

      def clear
        @method_cache.clear
        @instance_method_cache.clear
      end
    end
  end
end
