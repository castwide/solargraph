module Solargraph
  module LanguageServer
    module Message
      class Initialized < Base
        def process
          meths = []
          # Initial registration checks for explicit false to enable features
          # on clients that don't send configuration options
          meths.push 'textDocument/completion' if host.options['completion']
          meths.push 'textDocument/hover' if host.options['hover']
          meths.push 'textDocument/signatureHelp' if host.options['hover']
          meths.push 'textDocument/onTypeFormatting' if host.options['autoformat']
          host.register_capabilities meths
        end
      end
    end
  end
end
