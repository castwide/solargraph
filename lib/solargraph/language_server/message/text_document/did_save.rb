module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class DidSave < Base
          def process
            host.save params
          end
        end
      end
    end
  end
end
