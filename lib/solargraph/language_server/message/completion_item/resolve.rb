require 'reverse_markdown'

module Solargraph
  module LanguageServer
    module Message
      module CompletionItem
        class Resolve < Base
          def process
            available = host.resolvable.select{|s| s.path == params['detail']}
            STDERR.puts "Possible to resolve: #{available}"
            if available.empty?
              # @todo Error
            else
              set_result(
                params.merge(
                  documentation: ReverseMarkdown.convert(available[0].documentation)
                )
              )
            end
          end
        end
      end
    end
  end
end
