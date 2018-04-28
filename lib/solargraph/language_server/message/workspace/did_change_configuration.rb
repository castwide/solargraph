require 'uri'

module Solargraph::LanguageServer::Message::Workspace
  class DidChangeConfiguration < Solargraph::LanguageServer::Message::Base
    def process
      update = params['settings']['solargraph']

      meths = []
      meths.push 'textDocument/completion' if update.has_key?('completion') and update['completion'] and !host.options['completion']
      meths.push 'textDocument/hover' if update.has_key?('hover') and update['hover']  and !host.options['hover']
      meths.push 'textDocument/signatureHelp' if update.has_key?('hover') and update['hover'] and !host.options['hover']
      meths.push 'textDocument/onTypeFormatting' if update.has_key?('autoformat') and update['autoformat'] and !host.options['autoformat']
      host.register_capabilities meths unless meths.empty?

      meths = []
      meths.push 'textDocument/completion' if update.has_key?('completion') and !update['completion'] and host.options['completion']
      meths.push 'textDocument/hover' if update.has_key?('hover') and !update['hover'] and host.options['hover']
      meths.push 'textDocument/signatureHelp' if update.has_key?('hover') and !update['hover'] and host.options['hover']
      meths.push 'textDocument/onTypeFormatting' if update.has_key?('autoformat') and !update['autoformat'] and host.options['autoformat']
      host.unregister_capabilities meths unless meths.empty?

      host.configure update
    end
  end
end
