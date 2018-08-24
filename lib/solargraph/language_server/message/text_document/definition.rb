require 'uri'

module Solargraph::LanguageServer::Message::TextDocument
  class Definition < Base
    def process
      # source = host.read(params['textDocument']['uri'])
      # code_map = Solargraph::CodeMap.from_source(source, host.api_map)
      # offset = code_map.get_offset(params['position']['line'], params['position']['character'])
      # suggestions = code_map.define_symbol_at(offset)
      filename = uri_to_file(params['textDocument']['uri'])
      line = params['position']['line']
      col = params['position']['character']
      suggestions = host.definitions_at(filename, line, col)
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
