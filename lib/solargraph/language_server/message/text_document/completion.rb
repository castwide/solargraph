module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class Completion < Base
          def process
            text = host.read(filename)
            code_map = Solargraph::CodeMap.new(code: text, filename: filename, api_map: host.api_map, cursor: [params['position']['line'], params['position']['character']])
            offset = code_map.get_offset(params['position']['line'], params['position']['character'])
            suggestions = code_map.suggest_at(offset)
            items = suggestions.map do |sugg|
              {
                label: sugg.label,
                detail: sugg.path
              }
            end
            host.resolvable = suggestions
            set_result(
              isIncomplete: false,
              items: items
            )
          end
        end
      end
    end
  end
end
