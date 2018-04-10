module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class DidOpen < Base
          def process
            STDERR.puts "TextDocument reports open of #{params['textDocument']['uri']}"
            host.open params['textDocument']['uri'], params['textDocument']['text'], params['textDocument']['version']
          end
        end
      end
    end
  end
end
