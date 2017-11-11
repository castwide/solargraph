require 'solargraph/plugin/runtime_methods'

module Solargraph
  module Plugin
    class Runtime < Base
      include Solargraph::ServerMethods
      include Solargraph::Plugin::RuntimeMethods

      def post_initialize
        @port = available_port
        load_environment
      end

      def start
      end

      def stop
      end

      def runtime?
        true
      end

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
        respond_ok result.map(&:to_s)
      end

      protected

      def load_environment
        return if api_map.nil?
        api_map.required.each do |r|
          begin
            require r
          rescue Exception => e
            STDERR.puts "Failed to require #{r}: #{e.class} #{e.message}"
          end
        end
      end
    end
  end
end
