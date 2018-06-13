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
              workspace: {
                workspaceFolders: {
                  supported: true,
                  changeNotifications: true
                }
              }
            }
          }
          result[:capabilities].merge! static_completion unless dynamic_registration_for?('textDocument', 'completion')
          result[:capabilities].merge! static_signature_help unless dynamic_registration_for?('textDocument', 'signatureHelp')
          result[:capabilities].merge! static_on_type_formatting unless dynamic_registration_for?('textDocument', 'onTypeFormatting')
          result[:capabilities].merge! static_hover unless dynamic_registration_for?('textDocument', 'hover')
          result[:capabilities].merge! static_document_formatting unless dynamic_registration_for?('textDocument', 'formatting')
          result[:capabilities].merge! static_document_symbols unless dynamic_registration_for?('textDocument', 'documentSymbol')
          result[:capabilities].merge! static_workspace_symbols #unless dynamic_registration_for?('workspace', 'symbol')
          result[:capabilities].merge! static_definitions unless dynamic_registration_for?('textDocument', 'definition')
          result[:capabilities].merge! static_rename #unless dynamic_registration_for?('textDocument', 'rename')
          result[:capabilities].merge! static_references #unless dynamic_registration_for?('textDocument', 'references')
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

        def static_signature_help
          {
            signatureHelpProvider: {
              triggerCharacters: ['(', ',']
            }
          }
        end

        def static_on_type_formatting
          {
            documentOnTypeFormattingProvider: {
              firstTriggerCharacter: '{',
              moreTriggerCharacter: ['(']
            }
          }
        end

        def static_hover
          {
            hoverProvider: true
          }
        end

        def static_document_formatting
          {
            documentFormattingProvider: true
          }
        end

        def static_document_symbols
          {
            documentSymbolProvider: true
          }
        end

        def static_workspace_symbols
          {
            workspaceSymbolProvider: true
          }
        end

        def static_definitions
          {
            definitionProvider: true
          }
        end

        def static_rename
          {
            renameProvider: true
          }
        end

        def static_references
          {
            referencesProvider: true
          }
        end

        # @return [Boolean]
        def dynamic_registration_for? section, capability
          params['capabilities'] and
            params['capabilities'][section] and
            params['capabilities'][section][capability] and
            params['capabilities'][section][capability]['dynamicRegistration']
        end
      end
    end
  end
end
