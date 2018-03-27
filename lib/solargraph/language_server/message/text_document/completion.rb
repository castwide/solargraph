require 'time'

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class Completion < Base
          def process
            begin
              start = Time.now
              processed = false
              until processed
                host.synchronize do
                  if host.changing?(params['textDocument']['uri'])
                    STDERR.puts "Waiting..."
                    if Time.now - start > 1
                      set_result empty_result
                      break
                    end
                  else
                    inner_process
                    processed = true
                  end
                end
                sleep 0.1 unless processed
              end
            rescue Exception => e
              STDERR.puts e.message
              STDERR.puts e.backtrace
              set_error ErrorCodes::INTERNAL_ERROR, e.message
            end
          end

          private

          def inner_process
            filename = uri_to_file(params['textDocument']['uri'])
            line = params['position']['line']
            col = params['position']['character']
            pins = host.library.completions_at(filename, line, col)
            range = host.library.symbol_range_at(filename, line, col)
            items = []
            pins.each do |s|
              items.push s.completion_item.merge(
                textEdit: {
                  range: range,
                  newText: s.name
                }
              )
            end
            set_result(
              isIncomplete: false,
              items: items
            )
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
