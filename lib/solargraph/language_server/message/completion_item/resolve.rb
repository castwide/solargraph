require 'reverse_markdown'
require 'uri'

module Solargraph
  module LanguageServer
    module Message
      module CompletionItem
        class Resolve < Base
          def process
            host.synchronize do
              STDERR.puts "******************* RESOLUTION!"
              pin = host.resolvable[params['data']['uid']]
              if pin.nil?
                set_error(Solargraph::LanguageServer::ErrorCodes::INVALID_REQUEST, "Completion item could not be resolved")
              else
                STDERR.puts "... for #{pin.name}"
                pin.resolve host.library.api_map
                STDERR.puts "... which is now #{pin.return_type}"
                set_result(
                  # params.merge(pin.resolve_completion_item(host.library.api_map))
                  pin.resolve_completion_item(host.library.api_map)
                )
              end
            end
          end
        end
      end
    end
  end
end
