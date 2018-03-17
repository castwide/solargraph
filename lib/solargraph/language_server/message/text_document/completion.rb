module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class Completion < Base
          def process
            again = false
            host.synchronize do
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
                if host.changing?(params['textDocument']['uri'])
                  set_result(
                    isIncomplete: false,
                    items: []
                  )
                else
                  source = host.read(params['textDocument']['uri'])
                  code_map = Solargraph::CodeMap.from_source(source, host.api_map)
                  offset = code_map.get_offset(params['position']['line'], params['position']['character'])
                  range = code_map.symbol_range_at(offset)
                  suggestions = code_map.suggest_at(offset)
                  suggestion_map = {}
                  items = []
                  suggestions.each do |s|
                    items.push s.completion_item.merge(
                      textEdit: {
                        range: range,
                        newText: s.name
                      }
                    )
                    suggestion_map[s.object_id] = s
                  end
                  host.resolvable = suggestion_map
                  set_result(
                    isIncomplete: false,
                    items: items
                  )
                end
              rescue Exception => e
                if e.message.include?('Invalid offset') #and host.changing?(params['textDocument']['uri'])
                  STDERR.puts "Changing. Try again"
                  again = true
                else
                  STDERR.puts "#{e}"
                  STDERR.puts "#{e.backtrace}"
                  set_error Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, e.message
                end
              end
            end
            if again
              sleep 0.01
              process
            end
          end
        end
      end
    end
  end
end
