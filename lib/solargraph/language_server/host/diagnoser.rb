module Solargraph
  module LanguageServer
    class Host
      class Diagnoser
        def initialize host
          @host = host
          @mutex = Mutex.new
          @queue = []
          @stopped = true
        end

        # Schedule a file to be diagnosed.
        #
        # @param uri [String]
        # @return [void]
        def schedule uri
          mutex.synchronize { queue.push uri }
        end

        # Stop the diagnosis thread.
        #
        # @return [void]
        def stop
          @stopped = true
        end

        # True is the diagnoser is stopped.
        #
        # @return [Boolean]
        def stopped?
          @stopped
        end

        # Start the diagnosis thread.
        #
        # @return [self]
        def start
          return unless @stopped
          @stopped = false
          Thread.new do
            until stopped?
              sleep 0.1
              if !host.options['diagnostics']
                mutex.synchronize { queue.clear }
                next
              end
              begin
                current = nil
                mutex.synchronize { current = queue.shift }
                next if current.nil? or queue.include?(current)
                results = host.diagnose(current)
                host.send_notification "textDocument/publishDiagnostics", {
                  uri: current,
                  diagnostics: results
                }
              rescue DiagnosticsError => e
                STDERR.puts "Error in diagnostics: #{e.message}"
                options['diagnostics'] = false
                host.send_notification 'window/showMessage', {
                  type: LanguageServer::MessageTypes::ERROR,
                  message: "Error in diagnostics: #{e.message}"
                }
              end
            end
          end
          self
        end

        private

        # @return [Host]
        attr_reader :host

        # @return [Mutex]
        attr_reader :mutex

        # @return [Array]
        attr_reader :queue
      end
    end
  end
end
