module Solargraph
  module LanguageServer
    module Message
      # Messages in the Extended module are custom to the Solargraph
      # implementation of the language server. In the protocol, the method
      # names should start with "$/" so clients that don't recognize them can
      # ignore them, as per the LSP specification.
      #
      module Extended
        autoload :Document, 'solargraph/language_server/message/extended/document'
        autoload :Search, 'solargraph/language_server/message/extended/search'
      end
    end
  end
end
