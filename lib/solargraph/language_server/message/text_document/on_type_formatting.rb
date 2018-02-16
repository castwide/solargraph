module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class OnTypeFormatting < Base
          def process
            text = host.read(filename)
            code_map = Solargraph::CodeMap.new(code: text, filename: filename, api_map: host.api_map, cursor: [params['position']['line'], params['position']['character']])
            offset = code_map.get_offset(params['position']['line'], params['position']['character'])
            if code_map.string_at?(offset) and code_map.source.code[offset-2,2] == '#{'
              set_result(
                [
                  {
                    range: {
                      start: params['position'],
                      end: params['position']
                    },
                    newText: '}'
                  }
                ]
              )
            else
              set_error(
                Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, 'textDocument/onTypeFormatting is not implemented yet'
              )
            end
          end
        end
      end
    end
  end
end
