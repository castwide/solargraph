module Solargraph
  module LanguageServer
    module Message
      module CompletionItem
        # completionItem/resolve message handler
        #
        class Resolve < Base
          def process
            pins = host.locate_pins(params)
            set_result merge(pins)
          end

          private

          # @param pins [Array<Pin::Base>]
          # @return [Hash]
          def merge pins
            return params if pins.empty?
            docs = pins
                   .reject { |pin| pin.documentation.empty? }
                   .map { |pin| pin.resolve_completion_item[:documentation] }
            params
              .merge(pins.first.resolve_completion_item)
              .merge(documentation: docs.join("\n\n"))
          end
        end
      end
    end
  end
end
