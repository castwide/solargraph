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
          # FIXME: lsp default is utf-16, may have different position
          result[:capabilities][:positionEncoding] = 'utf-32' if params.dig('capabilities', 'general',
                                                                            'positionEncodings')&.include?('utf-32')
          result[:capabilities].merge! static_completion unless dynamic_registration_for?('textDocument', 'completion')
          result[:capabilities].merge! static_signature_help unless dynamic_registration_for?('textDocument',
                                                                                              'signatureHelp')
          # result[:capabilities].merge! static_on_type_formatting unless dynamic_registration_for?('textDocument', 'onTypeFormatting')
          result[:capabilities].merge! static_hover unless dynamic_registration_for?('textDocument', 'hover')
          result[:capabilities].merge! static_document_formatting unless dynamic_registration_for?('textDocument',
                                                                                                   'formatting')
          result[:capabilities].merge! static_document_symbols unless dynamic_registration_for?('textDocument',
                                                                                                'documentSymbol')
          result[:capabilities].merge! static_definitions unless dynamic_registration_for?('textDocument', 'definition')
          result[:capabilities].merge! static_type_definitions unless dynamic_registration_for?('textDocument',
                                                                                                'typeDefinition')
          result[:capabilities].merge! static_rename unless dynamic_registration_for?('textDocument', 'rename')
          result[:capabilities].merge! static_references unless dynamic_registration_for?('textDocument', 'references')
          result[:capabilities].merge! static_workspace_symbols unless dynamic_registration_for?('workspace', 'symbol')
          result[:capabilities].merge! static_folding_range unless dynamic_registration_for?('textDocument',
                                                                                             'foldingRange')
          result[:capabilities].merge! static_highlights unless dynamic_registration_for?('textDocument',
                                                                                          'documentHighlight')
          # @todo Temporarily disabled
          # result[:capabilities].merge! static_code_action unless dynamic_registration_for?('textDocument', 'codeAction')
          set_result result
        end

        private

        # @todo '?' methods should type like RBS 'boolish' rather than a strict true or false
        # @sg-ignore
        def support_workspace_folders?
          params['capabilities'] &&
            params['capabilities']['workspace'] &&
            params['capabilities']['workspace']['workspaceFolders'] &&
            params['workspaceFolders']
        end

        # @return [Hash{Symbol => undefined}]
        def static_completion
          return {} unless host.options['completion']
          {
            completionProvider: {
              resolveProvider: true,
              triggerCharacters: ['.', ':', '@']
            }
          }
        end

        # @return [Hash{Symbol => BasicObject}]
        def static_code_action
          {
            codeActionProvider: true,
            codeActionKinds: ['quickfix']
          }
        end

        # @return [Hash{Symbol => BasicObject}]
        def static_signature_help
          {
            signatureHelpProvider: {
              triggerCharacters: ['(', ',']
            }
          }
        end

        # @return [Hash{Symbol => Hash{Symbol => String, Array<String>}}]
        def static_on_type_formatting
          {
            documentOnTypeFormattingProvider: {
              firstTriggerCharacter: '{',
              moreTriggerCharacter: ['(']
            }
          }
        end

        # @return [Hash{Symbol => Boolean}]
        def static_hover
          return {} unless host.options['hover']
          {
            hoverProvider: true
          }
        end

        # @return [Hash{Symbol => Boolean}]
        def static_document_formatting
          return {} unless host.options['formatting']
          {
            documentFormattingProvider: true
          }
        end

        # @return [Hash{Symbol => Boolean}]
        def static_document_symbols
          return {} unless host.options['symbols']
          {
            documentSymbolProvider: true
          }
        end

        # @return [Hash{Symbol => Boolean}]
        def static_workspace_symbols
          {
            workspaceSymbolProvider: true
          }
        end

        # @return [Hash{Symbol => Boolean}]
        def static_definitions
          return {} unless host.options['definitions']
          {
            definitionProvider: true
          }
        end

        # @return [Hash{Symbol => Boolean}]
        def static_type_definitions
          return {} unless host.options['typeDefinitions']
          {
            typeDefinitionProvider: true
          }
        end

        # @return [Hash{Symbol => Hash{Symbol => Boolean}}]
        def static_rename
          {
            renameProvider: { prepareProvider: true }
          }
        end

        # @return [Hash{Symbol => Boolean}]
        def static_references
          return {} unless host.options['references']
          {
            referencesProvider: true
          }
        end

        # @return [Hash{Symbol => Boolean}]
        def static_folding_range
          return {} unless host.options['folding']
          {
            foldingRangeProvider: true
          }
        end

        # @return [Hash{Symbol => Boolean}]
        def static_highlights
          {
            documentHighlightProvider: true
          }
        end

        # @param section [String]
        # @param capability [String]
        # @todo Need support for RBS' boolish "type", which doesn't
        #   enforce strict true/false-ness
        # @sg-ignore
        def dynamic_registration_for? section, capability
          result = params['capabilities'] &&
                   params['capabilities'][section] &&
                   params['capabilities'][section][capability] &&
                   params['capabilities'][section][capability]['dynamicRegistration']
          host.allow_registration("#{section}/#{capability}") if result
          result
        end
      end
    end
  end
end
