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
      meths.push 'textDocument/formatting' if update.has_key?('formatting') and update['formatting'] and !host.options['formatting']
      meths.push 'textDocument/documentSymbol' if update.has_key?('symbols') and update['symbols'] and !host.options['symbols']
      meths.push 'workspace/workspaceSymbol' if update.has_key?('symbols') and update['symbols'] and !host.options['symbols']
      meths.push 'textDocument/definition' if update.has_key?('definitions') and update['definitions'] and !host.options['definitions']
      host.register_capabilities meths unless meths.empty?

      meths = []
      meths.push 'textDocument/completion' if update.has_key?('completion') and !update['completion'] and host.options['completion']
      meths.push 'textDocument/hover' if update.has_key?('hover') and !update['hover'] and host.options['hover']
      meths.push 'textDocument/signatureHelp' if update.has_key?('hover') and !update['hover'] and host.options['hover']
      meths.push 'textDocument/onTypeFormatting' if update.has_key?('autoformat') and !update['autoformat'] and host.options['autoformat']
      meths.push 'textDocument/formatting' if update.has_key?('formatting') and !update['formatting'] and host.options['formatting']
      meths.push 'textDocument/documentSymbol' if update.has_key?('symbols') and !update['symbols'] and host.options['symbols']
      meths.push 'workspace/workspaceSymbol' if update.has_key?('symbols') and !update['symbols'] and host.options['symbols']
      meths.push 'textDocument/definition' if update.has_key?('definitions') and !update['definitions'] and host.options['definitions']
      host.unregister_capabilities meths unless meths.empty?

      host.configure update
    end
  end
end
