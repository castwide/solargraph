module Solargraph
  module LanguageServer
    module Message
      class Initialize < Base
        def process
          host.prepare params['rootPath']
          set_result(
            capabilities: {
              textDocumentSync: 1, # @todo What should this be?
              completionProvider: {
                resolveProvider: true,
                triggerCharacters: ['.', ':', '@']
              },
              hoverProvider: true,
              definitionProvider: true,
              signatureHelpProvider: {
                triggerCharacters: ['(', ',']
              },
              documentFormattingProvider: true,
              documentOnTypeFormattingProvider: {
                firstTriggerCharacter: '{',
                moreTriggerCharacter: ['(']
              }
            }
          )
        end
      end
    end
  end
end
