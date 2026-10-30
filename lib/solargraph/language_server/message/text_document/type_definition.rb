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
            suggestions.map do |pin|
              loc = pin.best_location
              next if loc.nil? || loc.filename.nil?

              {
                uri: file_to_uri(loc.filename),
                range: loc.range.to_hash
              }
            end.compact
          end
        end
      end
    end
  end
end
