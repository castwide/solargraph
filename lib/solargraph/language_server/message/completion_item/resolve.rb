require 'reverse_markdown'
require 'uri'

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
              doc = ''
              if host.options['enablePages'] and resolved.kind != Solargraph::Suggestion::VARIABLE and !resolved.path.nil?
                doc.concat "[#{resolved.path}](solargraph:/document?query=#{URI.encode(resolved.path)})\n\n"
              end
              doc.concat ReverseMarkdown.convert(resolved.documentation)
              set_result(
                params.merge(
                  documentation: doc
                )
              )
            end
          end
        end
      end
    end
  end
end
