module Solargraph
  module LanguageServer
    module Message
      class Initialized < Base
        def process
          meths = []
          meths.push 'textDocument/completion' if host.options['completion']
          meths.push 'textDocument/hover' if host.options['hover']
          meths.push 'textDocument/signatureHelp' if host.options['hover']
          meths.push 'textDocument/onTypeFormatting' if host.options['autoformat']
          meths.push 'textDocument/formatting' if host.options['formatting']
          meths.push 'textDocument/documentSymbol' if host.options['symbols']
          # meths.push 'workspace/workspaceSymbol' if host.options['symbols']
          meths.push 'textDocument/definition' if host.options['definitions']
          meths.push 'textDocument/references' if host.options['references']
          meths.push 'textDocument/rename' if host.options['rename']
          host.register_capabilities meths unless meths.empty?
        end
      end
    end
  end
end
