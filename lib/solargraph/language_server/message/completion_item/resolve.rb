# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module CompletionItem
        # completionItem/resolve message handler
        #
        class Resolve < Base
          # Properties that must not be changed during completionItem/resolve
          # according to the LSP specification.
          #
          # @see https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_completion
          IMMUTABLE_FIELDS = %i[label kind sortText filterText insertText textEdit data].freeze

          def process
            pins = host.locate_pins(params)
            set_result merge(pins)
          end

          private

          # @param pins [Array<Pin::Base>]
          # @return [Hash]
          def merge pins
            original = params.transform_keys(&:to_sym)
            return original if pins.empty?
            docs = pins
                   .reject { |pin| pin.documentation.empty? && pin.return_type.undefined? }
            result = original
                     .merge(pins.first.resolve_completion_item)
                     .merge(documentation: markup_content(join_docs(docs)))
            result[:detail] = pins.first.detail
            IMMUTABLE_FIELDS.each { |field| result[field] = original[field] }
            result
          end

          # @param text [String]
          # @return [Hash{Symbol => String}, nil]
          def markup_content text
            return nil if text.strip.empty?
            {
              kind: 'markdown',
              value: text
            }
          end

          # @param pins [Array<Pin::Base>]
          # @return [String]
          def join_docs pins
            result = []
            last_link = nil
            pins.each do |pin|
              this_link = host.options['enablePages'] ? pin.link_documentation : pin.text_documentation
              result.push this_link if this_link && this_link != last_link && this_link != 'undefined'
              result.push pin.documentation unless result.last&.end_with?(pin.documentation)
              last_link = this_link
            end
            result.join("\n\n")
          end
        end
      end
    end
  end
end
