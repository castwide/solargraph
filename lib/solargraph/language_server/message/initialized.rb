module Solargraph
  module LanguageServer
    module Message
      class Initialized < Base
        def process
          host.register_capabilities %w[
            textDocument/completion
            textDocument/hover
            textDocument/signatureHelp
            textDocument/formatting
            textDocument/documentSymbol
            textDocument/definition
            textDocument/references
            textDocument/rename
            textDocument/prepareRename
            textDocument/foldingRange
            textDocument/codeAction
            workspace/symbol
          ]
        end
      end
    end
  end
end
