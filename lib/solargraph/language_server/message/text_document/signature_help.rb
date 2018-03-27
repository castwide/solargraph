module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class SignatureHelp < TextDocument::Base
          def process
            filename = uri_to_file(params['textDocument']['uri'])
            line = params['position']['line']
            col = params['position']['character']
            # @todo Make better assumptions about the beginning of the method
            suggestions = host.library.signatures_at(filename, line, col)
            info = []
            suggestions.each do |s|
              info.push s.signature_help
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
