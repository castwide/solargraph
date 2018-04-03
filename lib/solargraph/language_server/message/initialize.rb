module Solargraph
  module LanguageServer
    module Message
      class Initialize < Base
        def process
          STDERR.puts params.inspect
          host.configure params['initializationOptions']
          host.prepare params['rootPath']
          set_result(
            capabilities: {
              textDocumentSync: 2, # @todo What should this be?
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
              },
              documentSymbolProvider: true,
              workspaceSymbolProvider: true,
              workspace: {
                workspaceFolders: {
                  supported: true,
                  changeNotifications: true
                }
              }
            }
          )
        end
      end
    end
  end
end
