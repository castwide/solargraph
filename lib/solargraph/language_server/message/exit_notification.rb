module Solargraph
  module LanguageServer
    module Message
      class ExitNotification < Base
        def process
          host.stop
          exit
        end
      end
    end
  end
end
