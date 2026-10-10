# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class TypeDefinition < Base
          def process
            @line = params['position']['line']
            @column = params['position']['character']
            set_result(code_location || [])
          end

          private

          # @return [Array<Hash>, nil]
          def code_location
            suggestions = host.type_definitions_at(params['textDocument']['uri'], @line, @column)
            return nil if suggestions.nil? || suggestions.empty?
            suggestions.reject { |pin| pin.best_location.nil? || pin.best_location.filename.nil? }.map do |pin|
              {
                # @sg-ignore pin.location relies on location always resolved
                uri: file_to_uri(pin.best_location.filename),
                # @sg-ignore pin.location relies on location always resolved
                range: pin.best_location.range.to_hash
              }
            end
          end
        end
      end
    end
  end
end
