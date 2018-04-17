module Solargraph
  module LanguageServer
    module Message
      class Initialize < Base
        def process
          host.configure params['initializationOptions']
          host.prepare params['rootPath']
          set_result(
            # @todo Dynamic capabilities are stubbed here.
            capabilities: {
              textDocumentSync: 2, # @todo What should this be?
              # completionProvider: {
              #   resolveProvider: true,
              #   triggerCharacters: ['.', ':', '@']
              # },
              # hoverProvider: true,
              definitionProvider: true,
              # signatureHelpProvider: {
              #   triggerCharacters: ['(', ',']
              # },
              documentFormattingProvider: true,
              # documentOnTypeFormattingProvider: {
              #   firstTriggerCharacter: '{',
              #   moreTriggerCharacter: ['(']
              # },
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
          # Initialize dynamic options in case the client didn't send them
          host.options['completion'] ||= (host.options['completion'] != false)
          host.options['hover'] ||= (host.options['hover'] != false)
          host.options['autoformat'] ||= (host.options['autoformat'] != false)
        end
      end
    end
  end
end
