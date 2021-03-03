# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      class Initialize < Base
        def process
          host.configure params['initializationOptions']
          host.client_capabilities = params['capabilities']
          if support_workspace_folders?
            host.prepare_folders params['workspaceFolders']
          elsif params['rootUri']
            host.prepare UriHelpers.uri_to_file(params['rootUri'])
          else
            host.prepare params['rootPath']
          end
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
          # result[:capabilities].merge! static_on_type_formatting unless dynamic_registration_for?('textDocument', 'onTypeFormatting')
          result[:capabilities].merge! static_hover unless dynamic_registration_for?('textDocument', 'hover')
          result[:capabilities].merge! static_document_formatting unless dynamic_registration_for?('textDocument', 'formatting')
          result[:capabilities].merge! static_document_symbols unless dynamic_registration_for?('textDocument', 'documentSymbol')
          result[:capabilities].merge! static_definitions unless dynamic_registration_for?('textDocument', 'definition')
          result[:capabilities].merge! static_rename unless dynamic_registration_for?('textDocument', 'rename')
          result[:capabilities].merge! static_references unless dynamic_registration_for?('textDocument', 'references')
          result[:capabilities].merge! static_workspace_symbols unless dynamic_registration_for?('workspace', 'symbol')
          result[:capabilities].merge! static_folding_range unless dynamic_registration_for?('textDocument', 'foldingRange')
          # @todo Temporarily disabled
          # result[:capabilities].merge! static_code_action unless dynamic_registration_for?('textDocument', 'codeAction')
          set_result result
        end

        private

        def support_workspace_folders?
          params['capabilities'] &&
            params['capabilities']['workspace'] &&
            params['capabilities']['workspace']['workspaceFolders'] &&
            params['workspaceFolders']
        end

        def static_completion
          {
            completionProvider: {
              resolveProvider: true,
              triggerCharacters: ['.', ':', '@']
            }
          }
        end

        def static_code_action
          {
            codeActionProvider: true,
            codeActionKinds: ["quickfix"]
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
            renameProvider: {prepareProvider: true}
          }
        end

        def static_references
          {
            referencesProvider: true
          }
        end

        def static_folding_range
          {
            foldingRangeProvider: true
          }
        end

        # @param section [String]
        # @param capability [String]
        # @return [Boolean]
        def dynamic_registration_for? section, capability
          result = (params['capabilities'] &&
            params['capabilities'][section] &&
            params['capabilities'][section][capability] &&
            params['capabilities'][section][capability]['dynamicRegistration'])
          host.allow_registration("#{section}/#{capability}") if result
          result
        end
      end
    end
  end
end
