module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class DidOpen < Base
          def process
            host.library.open uri_to_file(params['textDocument']['uri']), params['textDocument']['text'], params['textDocument']['version']
            host.diagnose params['textDocument']['uri']
          end
        end
      end
    end
  end
end
