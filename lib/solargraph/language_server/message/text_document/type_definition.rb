# frozen_string_literal: true

module Solargraph::LanguageServer::Message::TextDocument
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
      # @sg-ignore Need to add nil check here
      return nil if suggestions.empty?
      # @sg-ignore Need to add nil check here
      suggestions.reject { |pin| pin.best_location.nil? || pin.best_location.filename.nil? }.map do |pin|
        {
          uri: file_to_uri(pin.best_location.filename),
          range: pin.best_location.range.to_hash
        }
      end
    end
  end
end
