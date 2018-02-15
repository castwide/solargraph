module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class Completion < Base
          def process
            begin
              kind_map = {
                'Class' => 7,
                'Constant' => 21,
                'Field' => 5,
                'Keyword' => 14,
                'Method' => 2,
                'Module' => 9,
                'Property' => 10,
                'Variable' => 6
              }
              text = host.read(filename)
              code_map = Solargraph::CodeMap.new(code: text, filename: filename, api_map: host.api_map, cursor: [params['position']['line'], params['position']['character']])
              offset = code_map.get_offset(params['position']['line'], params['position']['character'])
              suggestions = code_map.suggest_at(offset)
              items = suggestions.map do |sugg|
                {
                  label: sugg.label,
                  detail: sugg.path,
                  kind: kind_map[sugg.kind]
                }
              end
              host.resolvable = suggestions
              set_result(
                isIncomplete: false,
                items: items
              )
            rescue Exception => e
              set_error Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, e.message
            end
          end
        end
      end
    end
  end
end
