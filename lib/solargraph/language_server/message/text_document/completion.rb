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
              # text = host.read(filename).code
              # code_map = Solargraph::CodeMap.new(code: text, filename: filename, api_map: host.api_map, cursor: [params['position']['line'], params['position']['character']])
              if host.changing?(params['textDocument']['uri'])
                STDERR.puts "No completion items because host is changing #{params['textDocument']['uri']}"
                set_result(
                  isIncomplete: true,
                  items: []
                )
              else
                source = host.read(params['textDocument']['uri'])
                code_map = Solargraph::CodeMap.from_source(source, host.api_map)
                offset = code_map.get_offset(params['position']['line'], params['position']['character'])
                suggestions = code_map.suggest_at(offset)
                items = suggestions.map do |sugg|
                  detail = ''
                  detail += "(#{sugg.arguments.join(', ')}) " unless sugg.arguments.empty?
                  detail += "=> #{sugg.return_type}" unless sugg.return_type.nil?
                  {
                    label: sugg.label,
                    detail: detail,
                    kind: kind_map[sugg.kind],
                    data: {
                      identifier: sugg.location || sugg.path
                    }
                  }
                end
                suggestion_map = {}
                suggestions.each do |s|
                  suggestion_map[s.location || s.path] = s
                end
                host.resolvable = suggestion_map
                set_result(
                  isIncomplete: false,
                  items: items
                )
              end
            rescue Exception => e
              STDERR.puts "#{e}"
              STDERR.puts "#{e.backtrace}"
              set_error Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, e.message
            end
          end
        end
      end
    end
  end
end
