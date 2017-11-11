module Solargraph
  module Plugin
    module EventModule
      def post_init
      end

      def receive_data data
        if data.nil? or data.strip.empty?
          send_data "#{ { status: 'err', data: [], message: 'Invalid request' }.to_json }\n"
          return
        end
        parts = JSON.parse(data)
        result = []
        con = find_constant(parts['namespace'], parts['root'])
        unless con.nil?
          if (parts['scope'] == 'class')
            if parts['with_private']
              result.concat con.methods
            else
              result.concat con.public_methods
            end
          elsif (parts['scope'] == 'instance')
            if parts['with_private']
              result.concat con.instance_methods
            else
              result.concat con.public_instance_methods
            end
          end
        end
        send_data "#{result.to_json}\n"
        close_connection_after_writing
      end

      def unbind
      end

      private

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
