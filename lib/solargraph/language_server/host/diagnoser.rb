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

        def schedule filename
          @mutex.synchronize { queue.push filename }
        end

        def stop
          @stopped = true
        end

        def stopped?
          @stopped
        end

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
                # Diagnosis is broken into two parts to reduce the number of
                # times it runs while a document is changing
                current = nil
                mutex.synchronize do
                  current = queue.shift
                end
                next if current.nil?
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

        # @return [Set]
        attr_reader :queue
      end
    end
  end
end
