module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class DidOpen < Base
          def process
            host.open filename, params['textDocument']['text']
            publish_diagnostics
          end
        end
      end
    end
  end
end
