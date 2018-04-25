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
          STDERR.puts meths.inspect
          host.register_capabilities meths unless meths.empty?
        end
      end
    end
  end
end
