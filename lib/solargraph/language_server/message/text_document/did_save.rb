module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class DidSave < Base
          def process
            host.open filename, File.read(filename)
            publish_diagnostics
          end
        end
      end
    end
  end
end
