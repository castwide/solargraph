require 'uri'

module Solargraph::LanguageServer::Message::TextDocument
  class Hover < Base
    def process
      filename = uri_to_file(params['textDocument']['uri'])
      line = params['position']['line']
      col = params['position']['character']
      suggestions = host.library.definitions_at(filename, line, col)
      STDERR.puts "Pins for #{suggestions.map(&:name)}"
      contents = suggestions.map(&:hover)
      set_result(
        contents: {
          kind: 'markdown',
          value: contents.join("\n\n")
        }
      )
    end
  end
end
