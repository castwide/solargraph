module Solargraph
  module Plugin
    module RuntimeMethods
      def find_constant(namespace, root)
        result = nil
        parts = root.split('::')
        until parts.empty?
          result = inner_find_constant("#{parts.join('::')}::#{namespace}")
          parts.pop
          break unless result.nil?
        end
        result = inner_find_constant(namespace) if result.nil?
        result
      end

      private

      def inner_find_constant(namespace)
        cursor = Object
        parts = namespace.split('::')
        until parts.empty?
          here = parts.shift
          begin
            cursor = cursor.const_get(here)
          rescue NameError
            return nil
          end
        end
        cursor
      end
      end
  end
end
