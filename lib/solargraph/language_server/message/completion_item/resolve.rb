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
              pin = host.library.api_map.locate_pin(params['data']['location'])
              if pin.nil?
                # @todo This can happen if the pin came from the YardMap. Figure out a way to handle that.
                set_error(Solargraph::LanguageServer::ErrorCodes::INVALID_REQUEST, "Completion item could not be resolved")
              else
                set_result(
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
