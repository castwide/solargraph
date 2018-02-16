module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        module DiagnosticsQueue
          def start_diagnostics host, uri
            diagnostics_semaphore.synchronize {
              diagnostics_queue.push [host, uri]
            }
          end

          def more_diagnostics? host, uri
            result = nil
            diagnostics_semaphore.synchronize {
              result = diagnostics_queue.include?([host, uri])
            }
            result
          end

          def finish_diagnostics host, uri
            diagnostics_semaphore.synchronize {
              diagnostics_queue.slice!(diagnostics_queue.index([host, uri])) if diagnostics_queue.include?([host, uri])
            }              
          end

          private

          def diagnostics_semaphore
            @diagnostics_semaphore ||= Mutex.new
          end

          def diagnostics_queue
            @diagnostics_queue ||= []
          end
        end
      end
    end
  end
end
