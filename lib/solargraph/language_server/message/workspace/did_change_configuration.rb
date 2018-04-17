require 'uri'

module Solargraph::LanguageServer::Message::Workspace
  class DidChangeConfiguration < Solargraph::LanguageServer::Message::Base
    def process
      update = params['settings']['solargraph']

      meths = []
      meths.push 'textDocument/completion' if update['completion'] and !host.options['completion']
      meths.push 'textDocument/hover' if update['hover']  and !host.options['hover']
      meths.push 'textDocument/signatureHelp' if update['hover'] and !host.options['hover']
      meths.push 'textDocument/onTypeFormatting' if update['autoformat']  and !host.options['autoformat']
      host.register_capabilities meths unless meths.empty?

      meths = []
      meths.push 'textDocument/completion' if !update['completion'] and host.options['completion']
      meths.push 'textDocument/hover' if !update['hover'] and host.options['hover']
      meths.push 'textDocument/signatureHelp' if !update['hover'] and host.options['hover']
      meths.push 'textDocument/onTypeFormatting' if !update['autoformat'] and host.options['autoformat']
      host.unregister_capabilities meths unless meths.empty?

      host.configure params['settings']['solargraph']
    end
  end
end
