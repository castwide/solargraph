module Solargraph
  module LanguageServer
    module Message
      module CompletionItem
        # completionItem/resolve message handler
        #
        class Resolve < Base
          def process
            # @todo This method might need to read multiple pins, e.g., when a
            #   namespace has multiple pins, the first one returned might not
            #   have documentation.
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
