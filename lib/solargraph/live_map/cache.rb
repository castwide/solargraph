module Solargraph
  class LiveMap
    class Cache
      def initialize
        @method_cache = {}
        @constant_cache = {}
        @path_cache = {}
      end

      def get_methods options
        @method_cache[options]
      end

      def set_methods options, values
        @method_cache[options] = values
        values.each { |pin| @path_cache[pin.path] = pin }
      end

      def get_constants namespace, root
        @constant_cache[[namespace, root]]
      end

      def set_constants namespace, root, values
        @constant_cache[[namespace, root]] = values
      end

      def get_path_pin path
        @path_cache[path]
      end

      def clear
        @method_cache.clear
        @constant_cache.clear
        @path_cache.clear
      end
    end
  end
end
