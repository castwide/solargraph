module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class SignatureHelp < TextDocument::Base
          def process
            STDERR.puts "PORBLEM!" if host.changing?(params['textDocument']['uri'])
            filename = uri_to_file(params['textDocument']['uri'])
            line = params['position']['line']
            col = params['position']['character']
            suggestions = host.signatures_at(filename, line, col)
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
