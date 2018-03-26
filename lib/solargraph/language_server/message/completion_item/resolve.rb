require 'reverse_markdown'
require 'uri'

module Solargraph
  module LanguageServer
    module Message
      module CompletionItem
        class Resolve < Base
          def process
            pin = host.resolvable[params['data']['uid']]
            if pin.nil?
              set_error(Solargraph::LanguageServer::ErrorCodes::INVALID_REQUEST, "Completion item could not be resolved")
            else
              set_result(
                params.merge(pin.resolve_completion_item(host.library.api_map))
              )
            end
          end
        end
      end
    end
  end
end
