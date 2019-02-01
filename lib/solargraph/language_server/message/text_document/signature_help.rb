module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class SignatureHelp < TextDocument::Base
          def process
            line = params['position']['line']
            col = params['position']['character']
            suggestions = host.signatures_at(params['textDocument']['uri'], line, col)
            info = suggestions.map(&:signature_help)
            set_result({
              signatures: info
            })
          end
        end
      end
    end
  end
end
