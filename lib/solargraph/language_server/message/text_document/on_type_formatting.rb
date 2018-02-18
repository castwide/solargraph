module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class OnTypeFormatting < Base
          def process
            src = host.read(filename)
            offset = src.get_offset(params['position']['line'], params['position']['character'])
            if src.string_at?(offset-1) and params['ch'] == '{' and src.code[offset-2,2] == '#{'
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
