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
              more = {}
              if resolved.has_doc?
                doc = ''
                if host.options['enablePages'] and resolved.kind != Solargraph::Suggestion::VARIABLE and !resolved.path.nil?
                  doc.concat "[#{resolved.path}](solargraph:/document?query=#{URI.encode(resolved.path)})\n\n"
                end
                doc.concat ReverseMarkdown.convert(resolved.documentation)
                more['documentation'] = doc unless doc.strip.empty?
              end
              if resolved.return_type.nil? and resolved.pin.kind_of?(Solargraph::Pin::BaseVariable)
                rt = host.api_map.infer_assignment_node_type(resolved.pin.node, resolved.pin.namespace)
                more['detail'] = "=> #{rt}" unless rt.nil?
              end
              set_result(
                params.merge(more)
              )
            end
          end
        end
      end
    end
  end
end
