module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        autoload :Base, 'solargraph/language_server/message/text_document/base'
        autoload :Completion, 'solargraph/language_server/message/text_document/completion'
        autoload :DidOpen, 'solargraph/language_server/message/text_document/did_open'
        autoload :DidChange, 'solargraph/language_server/message/text_document/did_change'
        autoload :DidClose, 'solargraph/language_server/message/text_document/did_close'
        autoload :DidSave, 'solargraph/language_server/message/text_document/did_save'
        autoload :Hover, 'solargraph/language_server/message/text_document/hover'
        autoload :SignatureHelp, 'solargraph/language_server/message/text_document/signature_help'
        autoload :DiagnosticsQueue, 'solargraph/language_server/message/text_document/diagnostics_queue'
      end
    end
  end
end
