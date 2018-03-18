require 'uri'

module Solargraph::LanguageServer::Message::TextDocument
  class Definition < Base
    def process
      source = host.read(params['textDocument']['uri'])
      code_map = Solargraph::CodeMap.from_source(source, host.api_map)
      offset = code_map.get_offset(params['position']['line'], params['position']['character'])
      suggestions = code_map.define_symbol_at(offset)
      locations = suggestions.map do |pin|
        STDERR.puts pin.location
        unless pin.location.nil?
          parts = pin.location.split(':')
          char = parts.pop.to_i
          line = parts.pop.to_i
          filename = parts.join(':')
          {
            uri: file_to_uri(filename),
            range: {
              start: {
                line: line,
                character: char
              },
              end: {
                line: line,
                character: char
              }
            }
          }
        end
      end
      set_result locations
      # set_error Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, "Not implemented"
    end
  end
end
