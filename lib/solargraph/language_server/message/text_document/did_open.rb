module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class DidOpen < Base
          def process
            host.open params['textDocument']
            publish_diagnostics
          end
        end
      end
    end
  end
end
