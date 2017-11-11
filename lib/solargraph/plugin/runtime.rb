require 'solargraph/plugin/runtime_methods'

module Solargraph
  module Plugin
    class Runtime < Base
      include Solargraph::ServerMethods
      include Solargraph::Plugin::RuntimeMethods

      def post_initialize
        @port = available_port
      end

      def start
        if @job.nil?
          args = ['plugin', self.class.to_s, '--port', @port.to_s, '--ppid', Process.pid.to_s]
          opts = {}
          unless can_posix?
            args.push '<NUL'
            opts[:new_pgroup] = true
          end
          @job = spawn('solargraph', *args, opts)
        end
      end

      def stop
        unless @job.nil?
          if can_posix?
            Process.kill("TERM", @job)
          else
            Process.kill("INT", @job)
          end
          @job = nil
        end
      end

      def runtime?
        true
      end

      def get_methods namespace:, root:, scope:, with_private: false
        params = {
          scope: scope, namespace: namespace, root: root, with_private: with_private
        }
        begin
          s = TCPSocket.open('localhost', @port)
          s.puts params.to_json
          data = s.gets
          s.close
          return respond_ok([]) if data.nil?
          respond_ok JSON.parse(data)
        rescue Errno::ECONNREFUSED => e
          STDERR.puts "The Runtime plugin is not ready yet. #{e.inspect}"
          respond_err e
        end
      end
  
      def get_methods_old namespace:, root:, scope:, with_private: false
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

      def self.serve workspace, port, ppid
        Solargraph::Plugin::Server.new(workspace, port, ppid).run
      end

      private

      def can_posix?
        Signal.list.include?("HUP")
      end  
    end
  end
end
