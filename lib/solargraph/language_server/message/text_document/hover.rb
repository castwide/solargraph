require 'uri'

module Solargraph::LanguageServer::Message::TextDocument
  class Hover < Base
    def process
      source = host.read(params['textDocument']['uri'])
      code_map = Solargraph::CodeMap.from_source(source, host.api_map)
      offset = code_map.get_offset(params['position']['line'], params['position']['character'])
      suggestions = code_map.define_symbol_at(offset)
      contents = suggestions.map do |sugg|
        info = link_documentation(sugg.path)
        info.concat "\n\n#{ReverseMarkdown.convert(sugg.documentation)}" unless sugg.documentation.nil? or sugg.documentation.empty?
        info
      end
      host.resolvable = suggestions
      set_result(
        contents: {
          kind: 'markdown',
          value: contents.join("\n\n")
        }
      )
    end

    private
    
    def link_documentation path
      uri = "solargraph:/document?query=" + URI.encode(path)
      "[#{path}](#{uri})"
    end
  end
end
