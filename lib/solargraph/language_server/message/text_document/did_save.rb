module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class DidSave < Base
          def process
            STDERR.puts "TODO: TextDocument saved"
            host.save params
          end
        end
      end
    end
  end
end
