module Solargraph
  module LanguageServer
    module Message
      module CompletionItem
        # completionItem/resolve message handler
        #
        class Resolve < Base
          def process
            pin = host.locate_pin params
            if pin.nil?
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
