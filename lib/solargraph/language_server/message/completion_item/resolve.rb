require 'reverse_markdown'
require 'uri'

module Solargraph
  module LanguageServer
    module Message
      module CompletionItem
        class Resolve < Base
          def process
            if params['data']['location'].nil?
              set_result params
              return
            end
            host.synchronize do
              # pin = host.resolvable[params['data']['uid']]
              pin = host.library.api_map.locate_pin(params['data']['location'])
              if pin.nil?
                set_error(Solargraph::LanguageServer::ErrorCodes::INVALID_REQUEST, "Completion item could not be resolved")
              else
                pin.resolve host.library.api_map
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
