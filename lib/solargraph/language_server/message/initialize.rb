module Solargraph
  module LanguageServer
    module Message
      class Initialize < Base
        def process
          STDERR.puts "Initialize: #{params.inspect}"
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
              }
            }
          )
        end
      end
    end
  end
end
