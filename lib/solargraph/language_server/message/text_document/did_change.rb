module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class DidChange < Base
          def process
            host.change filename, params['contentChanges'][0]['text']
            publish_diagnostics
          end
        end
      end
    end
  end
end
