require 'reverse_markdown'
require 'uri'

module Solargraph
  module LanguageServer
    module Message
      module CompletionItem
        class Resolve < Base
          def process
            host.synchronize do
              pin = nil
              pin = host.library.locate_pin(params['data']['location']) unless params['data']['location'].nil?
              if pin.nil?
                pin = host.library.path_pins(params['data']['path']).first
              end
              if pin.nil?
                set_error(Solargraph::LanguageServer::ErrorCodes::INVALID_REQUEST, "Completion item could not be resolved")
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
end
