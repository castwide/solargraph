require 'uri'

module Solargraph::LanguageServer::Message::TextDocument
  class Hover < Base
    def process
      text = host.read(filename)
      code_map = Solargraph::CodeMap.new(code: text, filename: filename, api_map: host.api_map, cursor: [params['position']['line'], params['position']['character']])
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
