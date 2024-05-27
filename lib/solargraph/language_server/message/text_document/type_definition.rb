# frozen_string_literal: true

module Solargraph::LanguageServer::Message::TextDocument
  class TypeDefinition < Base
    def process
      @line = params['position']['line']
      @column = params['position']['character']
      set_result(code_location || [])
    end

    private

    def code_location
      suggestions = host.type_definitions_at(params['textDocument']['uri'], @line, @column)
      return nil if suggestions.empty?
      suggestions.reject { |pin| pin.location.nil? || pin.location.filename.nil? }.map do |pin|
        {
          uri: file_to_uri(pin.location.filename),
          range: pin.location.range.to_hash
        }
      end
    end
  end
end
