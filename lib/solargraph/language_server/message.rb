require 'solargraph'
require 'uri'
require 'thread'

module Solargraph
  module LanguageServer
    module Message
      autoload :Base,                 'solargraph/language_server/message/base'
      autoload :Initialize,           'solargraph/language_server/message/initialize'
      autoload :Initialized,          'solargraph/language_server/message/initialized'
      autoload :TextDocument,         'solargraph/language_server/message/text_document'
      autoload :CompletionItem,       'solargraph/language_server/message/completion_item'
      autoload :CancelRequest,        'solargraph/language_server/message/cancel_request'
      autoload :MethodNotFound,       'solargraph/language_server/message/method_not_found'
      autoload :MethodNotImplemented, 'solargraph/language_server/message/method_not_implemented'
      autoload :Extended,             'solargraph/language_server/message/extended'
      autoload :Shutdown,             'solargraph/language_server/message/shutdown'
      autoload :ExitNotification,     'solargraph/language_server/message/exit_notification'
      autoload :Workspace,            'solargraph/language_server/message/workspace'

      class << self
        def register path, message_class
          method_map[path] = message_class
        end

        # @param path [String]
        # @return [Solargraph::LanguageServer::Message::Base]
        def select path
          if method_map.has_key?(path)
            method_map[path]
          elsif path.start_with?('$/')
            MethodNotImplemented
          else
            STDERR.puts "Method not found: #{path}"
            MethodNotFound
          end
        end

        private

        def method_map
          @method_map ||= {}
        end
      end

      register 'initialize',                      Initialize
      register 'initialized',                     Initialized
      register 'textDocument/completion',         TextDocument::Completion
      register 'completionItem/resolve',          CompletionItem::Resolve
      register 'textDocument/signatureHelp',      TextDocument::SignatureHelp
      register 'textDocument/didOpen',            TextDocument::DidOpen
      register 'textDocument/didChange',          TextDocument::DidChange
      register 'textDocument/didSave',            TextDocument::DidSave
      register 'textDocument/didClose',           TextDocument::DidClose
      register 'textDocument/hover',              TextDocument::Hover
      register 'textDocument/definition',         TextDocument::Definition
      register 'textDocument/onTypeFormatting',   TextDocument::OnTypeFormatting
      register 'workspace/didChangeWatchedFiles', Workspace::DidChangeWatchedFiles
      register '$/cancelRequest',                 CancelRequest
      register '$/solargraph/document',           Extended::Document
      register '$/solargraph/search',             Extended::Search
      register 'shutdown',                        Shutdown
      register 'exit',                            ExitNotification
    end
  end
end
