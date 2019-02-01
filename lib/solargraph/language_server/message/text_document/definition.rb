require 'uri'

module Solargraph::LanguageServer::Message::TextDocument
  class Definition < Base
    def process
      line = params['position']['line']
      col = params['position']['character']
      suggestions = host.definitions_at(params['textDocument']['uri'], line, col)
      locations = suggestions.reject{|pin| pin.location.nil?}.map do |pin|
        {
          uri: file_to_uri(pin.location.filename),
          range: pin.location.range.to_hash
        }
      end
      set_result locations
    end
  end
end
