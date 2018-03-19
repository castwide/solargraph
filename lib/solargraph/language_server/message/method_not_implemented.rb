module Solargraph
  module LanguageServer
    module Message
      class MethodNotImplemented < Base
        set_error(
          Solargraph::LanguageServer::ErrorCodes::METHOD_NOT_FOUND,
          "Method not implemented: #{request['message']}"
        )
      end
    end
  end
end
