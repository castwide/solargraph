module Solargraph
  module LanguageServer
    module Message
      class Shutdown < Base
        def process
          set_result({})
        end
      end
    end
  end
end
