require 'reverse_markdown'
require 'uri'

module Solargraph
  module LanguageServer
    module Message
      module CompletionItem
        class Resolve < Base
          def process
            pin = host.locate_pin params
            if pin.nil?
              # set_error(Solargraph::LanguageServer::ErrorCodes::INVALID_REQUEST, "Completion item could not be resolved")
              set_result params
            else
              set_result(
                params.merge(pin.resolve_completion_item)
              )
            end
          end
        end
      end
    end
  end
end
