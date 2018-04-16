module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class OnTypeFormatting < Base
          def process
            src = host.send(:library).checkout(uri_to_file(params['textDocument']['uri']))
            fragment = src.fragment_at(params['position']['line'], params['position']['character'])
            offset = fragment.send(:offset)
            if fragment.string? and params['ch'] == '{' and src.code[offset-2,2] == '#{'
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
