module Solargraph
  module Plugin
    class Runtime < Base
      def post_initialize
        @io = IO.popen('solargraph-runtime', 'r+')
        send_require api_map.required unless api_map.nil?
        at_exit { @io.close unless @io.closed? }
        ObjectSpace.define_finalizer self do
          @io.close unless @io.closed?
        end
      end

      # @return [Boolean]
      def runtime?
        true
      end

      # Get an array of method names.
      #
      # @return [Array<String>]
      def get_methods namespace:, root:, scope:, with_private: false
        response = send_get_methods(namespace, root, scope, with_private)
        response['data']
      end

      # Get an array of constant names.
      #
      # @return [Array<String>]
      def get_constants namespace, root
        response = send_get_constants namespace, root
        response['data']
      end

      def get_fqns namespace, root
        response = send_get_fqns namespace, root
        response['data']
      end

      private

      def send_require paths
        cmd = {
          command: 'require',
          paths: paths
        }
        transact cmd
      end

      def send_get_methods namespace, root, scope, with_private
        cmd = {
          command: 'methods',
          params: {
            namespace: namespace,
            root: root,
            scope: scope,
            with_private: with_private
          }
        }
        transact cmd
      end

      def send_get_constants namespace, root
        cmd = {
          command: 'constants',
          params: {
            namespace: namespace,
            root: root
          }
        }
        transact cmd
      end

      def send_get_fqns namespace, root
        cmd = {
          command: 'fqns',
          params: {
            namespace: namespace,
            root: root
          }
        }
        transact cmd
      end

      def transact cmd
        @io.puts cmd.to_json
        @io.flush
        result = @io.gets
        JSON.parse(result)
      end
    end
  end
end
