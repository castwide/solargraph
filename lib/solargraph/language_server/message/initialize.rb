module Solargraph
  module LanguageServer
    module Message
      class Initialize < Base
        def process
          host.configure params['initializationOptions']
          host.prepare params['rootPath']
          result = {
            capabilities: {
              textDocumentSync: 2, # @todo What should this be?
              definitionProvider: true,
              renameProvider: true,
              workspace: {
                workspaceFolders: {
                  supported: true,
                  changeNotifications: true
                }
              },
              referencesProvider: true
            }
          }
          result[:capabilities].merge! static_completion unless dynamic_completion?
          result[:capabilities].merge! static_signature_help unless dynamic_signature_help?
          result[:capabilities].merge! static_on_type_formatting unless dynamic_on_type_formatting?
          result[:capabilities].merge! static_hover unless dynamic_hover?
          result[:capabilities].merge! static_document_formatting unless dynamic_document_formatting?
          result[:capabilities].merge! static_document_symbols unless dynamic_document_symbols?
          set_result result
        end

        private

        def static_completion
          {
            completionProvider: {
              resolveProvider: true,
              triggerCharacters: ['.', ':', '@']
            }
          }
        end

        def dynamic_completion?
          params['capabilities'] and
            params['capabilities']['textDocument'] and
            params['capabilities']['textDocument']['completion'] and
            params['capabilities']['textDocument']['completion']['dynamicRegistration']
        end

        def static_signature_help
          {
            signatureHelpProvider: {
              triggerCharacters: ['(', ',']
            }
          }
        end

        def dynamic_signature_help?
          params['capabilities'] and
            params['capabilities']['textDocument'] and
            params['capabilities']['textDocument']['signatureHelp'] and
            params['capabilities']['textDocument']['signatureHelp']['dynamicRegistration']
        end

        def static_on_type_formatting
          {
            documentOnTypeFormattingProvider: {
              firstTriggerCharacter: '{',
              moreTriggerCharacter: ['(']
            }
          }
        end

        def dynamic_on_type_formatting?
          params['capabilities'] and
            params['capabilities']['textDocument'] and
            params['capabilities']['textDocument']['onTypeFormatting'] and
            params['capabilities']['textDocument']['onTypeFormatting']['dynamicRegistration']
        end

        def static_hover
          {
            hoverProvider: true
          }
        end

        def dynamic_hover?
          params['capabilities'] and
            params['capabilities']['textDocument'] and
            params['capabilities']['textDocument']['hover'] and
            params['capabilities']['textDocument']['hover']['dynamicRegistration']
        end

        def static_document_formatting
          {
            documentFormattingProvider: true
          }
        end

        def dynamic_document_formatting?
          params['capabilities'] and
            params['capabilities']['textDocument'] and
            params['capabilities']['textDocument']['hover'] and
            params['capabilities']['textDocument']['hover']['dynamicRegistration']
        end

        def static_document_symbols
          {
            documentSymbolProvider: true
          }
        end

        def dynamic_document_symbols?
          params['capabilities'] and
            params['capabilities']['textDocument'] and
            params['capabilities']['textDocument']['documentSymbol'] and
            params['capabilities']['textDocument']['documentSymbol']['dynamicRegistration']
        end

        def static_workspace_symbols
          {
            workspaceSymbolProvider: true
          }
        end

        def dynamic_workspace_symbols?
          params['capabilities'] and
            params['capabilities']['workspace'] and
            params['capabilities']['workspace']['symbol'] and
            params['capabilities']['workspace']['symbol']['dynamicRegistration']
        end
      end
    end
  end
end
