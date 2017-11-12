module Solargraph
  module Plugin
    class Runtime < Base
      def post_initialize
        return if api_map.nil?
        api_map.required.each do |r|
          begin
            require r
          rescue Exception => e
            STDERR.puts "Failed to require #{r}: #{e.class} #{e.message}"
          end
        end
      end

      def runtime?
        true
      end

      # @return [Array<String>]
      def get_methods namespace:, root:, scope:, with_private: false
        result = []
        con = find_constant(namespace, root)
        unless con.nil?
          if (scope == 'class')
            if with_private
              result.concat con.methods
            else
              result.concat con.public_methods
            end
          elsif (scope == 'instance')
            if with_private
              result.concat con.instance_methods
            else
              result.concat con.public_instance_methods
            end
          end
        end
        result.map(&:to_s)
      end

      # @return [Array<String>]
      def get_constants namespace
        namespace = 'Object' if namespace.nil? or namespace.empty?
        # @type [Class]
        con = find_constant(namespace)
        con.constants.map(&:to_s)
      end

      private

      def find_constant(namespace, root = '')
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
