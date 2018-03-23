module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class OnTypeFormatting < Base
          def process
            src = host.read(params['textDocument']['uri'])
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
              set_result []
            end
          end
        end
      end
    end
  end
end
