module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class DidSave < Base
          def process
            STDERR.puts "Saving document"
            host.open params['textDocument']
            publish_diagnostics
          end
        end
      end
    end
  end
end
