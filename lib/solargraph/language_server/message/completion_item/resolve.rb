require 'reverse_markdown'

module Solargraph
  module LanguageServer
    module Message
      module CompletionItem
        class Resolve < Base
          def process
            resolved = host.resolvable[params['data']['identifier']]
            if resolved.nil?
              set_error(Solargraph::LanguageServer::ErrorCodes::INVALID_REQUEST, "Completion item could not be resolved")
            else
              set_result(
                params.merge(
                  documentation: ReverseMarkdown.convert(resolved.documentation)
                )
              )
            end
          end
        end
      end
    end
  end
end
