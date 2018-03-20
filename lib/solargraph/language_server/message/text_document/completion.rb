require 'time'

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class Completion < Base
          def process
            again = true
            started = Time.now
            while again
              if Time.now - started > 1
                set_result empty_result
              else
                unless host.changing?(params['textDocument']['uri'])
                  host.synchronize do
                    begin
                      inner_process
                      again = false
                    rescue Exception => e
                      if e.message.include?('Invalid offset')
                        STDERR.puts "Invalid offset. Try again?"
                      else
                        STDERR.puts "#{e}"
                        STDERR.puts "#{e.backtrace}"
                        set_error Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, e.message
                        again = false
                      end
                    end
                  end
                  sleep 0.01 if again
                end
              end
            end
          end

          private

          def inner_process
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
          end

          def empty_result
            {
              isIncomplete: false,
              items: []
            }
          end
        end
      end
    end
  end
end
