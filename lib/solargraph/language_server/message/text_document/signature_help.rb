module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class SignatureHelp < TextDocument::Base
          def process
            source = host.read(params['textDocument']['uri'])
            code_map = Solargraph::CodeMap.from_source(source, host.api_map)
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
