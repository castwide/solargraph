module Solargraph
  module Plugin
    class Runtime < Base
      def post_initialize
        start_process
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

      def refresh
        if api_map.nil?
          false
        else
          if @current_required != api_map.required
            @io.close unless @io.closed?
            start_process
            true
          else
            false
          end
        end
      end

      private

      def start_process
        STDERR.puts "Starting Runtime process"
        @io = IO.popen('solargraph-runtime', 'r+')
        unless api_map.nil?
          STDERR.puts "Required paths given to Runtime: #{api_map.required}"
          send_require api_map.required
          @current_required = api_map.required.clone
        end
      end

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
