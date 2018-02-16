module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class SignatureHelp < TextDocument::Base
          def process
            text = host.read(filename)
            code_map = Solargraph::CodeMap.new(code: text, filename: filename, api_map: host.api_map, cursor: [params['position']['line'], params['position']['character']])
            offset = code_map.get_offset(params['position']['line'], params['position']['character'])
            sugg = code_map.signatures_at(offset)
            info = []
            sugg.each do |s|
              info.push({
                label: s.label + '(' + s.arguments.join(', ') + ')',
                documentation: ReverseMarkdown.convert(s.documentation)
              })
            end
            set_result({
              signatures: info
            })
          end
        end
      end
    end
  end
end
