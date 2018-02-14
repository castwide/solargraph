require 'solargraph'
require 'uri'
require 'thread'

module Solargraph
  module LanguageServer
    module Message
      autoload :Base, 'solargraph/language_server/message/base'
      autoload :Initialize, 'solargraph/language_server/message/initialize'
      autoload :Initialized, 'solargraph/language_server/message/initialized'
      autoload :TextDocument, 'solargraph/language_server/message/text_document'
      autoload :CompletionItem, 'solargraph/language_server/message/completion_item'
      autoload :CancelRequest, 'solargraph/language_server/message/cancel_request'

      class << self
        def register path, message_class
          method_map[path] = message_class
        end

        def select path
          method_map[path]
        end

        private

        def method_map
          @method_map ||= {}
        end
      end

      register 'initialize', Initialize
      register 'initialized', Initialized
      register 'textDocument/completion', TextDocument::Completion
      register 'completionItem/resolve', CompletionItem::Resolve
      register 'textDocument/didOpen', TextDocument::DidOpen
      register 'textDocument/didChange', TextDocument::DidChange
      register 'textDocument/didSave', TextDocument::DidSave
      register 'textDocument/hover', TextDocument::Hover
      register '$/cancelRequest', CancelRequest
    end
  end
end
