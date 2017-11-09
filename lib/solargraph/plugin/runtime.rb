require 'solargraph/plugin/runtime_methods'

module Solargraph
  module Plugin
    class Runtime < Base
      include Solargraph::Plugin::RuntimeMethods

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
    end
  end
end
