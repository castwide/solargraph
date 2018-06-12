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
          result[:capabilities].merge! static_completion unless dynamic_completion?
          result[:capabilities].merge! static_signature_help unless dynamic_signature_help?
          result[:capabilities].merge! static_on_type_formatting unless dynamic_on_type_formatting?
          result[:capabilities].merge! static_hover unless dynamic_hover?
          result[:capabilities].merge! static_document_formatting unless dynamic_document_formatting?
          result[:capabilities].merge! static_document_symbols unless dynamic_document_symbols?
          result[:capabilities].merge! static_workspace_symbols unless dynamic_workspace_symbols?
          result[:capabilities].merge! static_definitions unless dynamic_definitions?
          result[:capabilities].merge! static_rename unless dynamic_rename?
          result[:capabilities].merge! static_references unless dynamic_references?
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
          dynamic_registration_for? 'textDocument', 'completion'
        end

        def static_signature_help
          {
            signatureHelpProvider: {
              triggerCharacters: ['(', ',']
            }
          }
        end

        def dynamic_signature_help?
          dynamic_registration_for? 'textDocument', 'signatureHelp'
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
          dynamic_registration_for? 'textDocument', 'onTypeFormatting'
        end

        def static_hover
          {
            hoverProvider: true
          }
        end

        def dynamic_hover?
          dynamic_registration_for? 'textDocument', 'hover'
        end

        def static_document_formatting
          {
            documentFormattingProvider: true
          }
        end

        def dynamic_document_formatting?
          dynamic_registration_for? 'textDocument', 'formatting'
        end

        def static_document_symbols
          {
            documentSymbolProvider: true
          }
        end

        def dynamic_document_symbols?
          dynamic_registration_for? 'textDocument', 'documentSymbol'
        end

        def static_workspace_symbols
          {
            workspaceSymbolProvider: true
          }
        end

        def dynamic_workspace_symbols?
          dynamic_registration_for? 'workspace', 'symbol'
        end

        def static_definitions
          {
            definitionProvider: true
          }
        end

        def dynamic_definitions?
          dynamic_registration_for? 'textDocument', 'definition'
        end

        def static_rename
          {
            renameProvider: true
          }
        end

        def dynamic_rename?
          dynamic_registration_for? 'textDocument', 'rename'
        end

        def static_references
          {
            referencesProvider: true
          }
        end

        def dynamic_references?
          dynamic_registration_for? 'textDocument', 'references'
        end

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
