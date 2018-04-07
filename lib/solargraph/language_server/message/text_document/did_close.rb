module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class DidClose < Base
          def process
            STDERR.puts "Closing file #{params['textDocument']['uri']}"
            host.close params['textDocument']['uri']
          end
        end
      end
    end
  end
end
