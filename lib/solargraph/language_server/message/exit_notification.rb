module Solargraph
  module LanguageServer
    module Message
      class ExitNotification < Base
        def process
          EventMachine.stop
          exit
        end
      end
    end
  end
end
