module Solargraph
  module LanguageServer
    module Message
      class MethodNotFound < Base
        def process
          set_error(
            Solargraph::LanguageServer::ErrorCodes::METHOD_NOT_FOUND,
            "Method not found: #{request['message']}"
          )
        end
      end
    end
  end
end
