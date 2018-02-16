module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        module DiagnosticsQueue
          def start_diagnostics uri
            diagnostics_semaphore.synchronize {
              diagnostics_queue.push uri
            }
          end

          def more_diagnostics? uri
            result = nil
            diagnostics_semaphore.synchronize {
              result = diagnostics_queue.include?(uri)
            }
            result
          end

          def finish_diagnostics uri
            diagnostics_semaphore.synchronize {
              diagnostics_queue.slice!(diagnostics_queue.index(uri)) if diagnostics_queue.include?(uri)
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
