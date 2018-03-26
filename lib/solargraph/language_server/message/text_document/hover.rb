require 'uri'

module Solargraph::LanguageServer::Message::TextDocument
  class Hover < Base
    def process
      filename = uri_to_file(params['textDocument']['uri'])
      line = params['position']['line']
      col = params['position']['character']
      suggestions = host.library.definitions_at(filename, line, col)
      contents = suggestions.map do |sugg|
        sugg.hover(host.library.api_map)
      end
      set_result(
        contents: {
          kind: 'markdown',
          value: contents.join("\n\n")
        }
      )
    end
  end
end
