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
            result = params
              .merge(pins.first.resolve_completion_item)
              .merge(documentation: markup_content(docs.join("\n\n")))
            result[:detail] = host.probe(params)
            result
          end

          # @param text [String]
          # @return [Hash{Symbol => String}]
          def markup_content text
            return nil if text.strip.empty?
            {
              kind: 'markdown',
              value: text
            }
          end
        end
      end
    end
  end
end
