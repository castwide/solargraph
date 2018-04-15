require 'time'

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class Completion < Base
          def process
            start = Time.now
            processed = false
            until processed
              if host.changing?(params['textDocument']['uri'])
                if Time.now - start > 1
                  # set_error Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, 'Completion request timed out'
                  set_result empty_result
                  processed = true
                end
              else
                inner_process
                processed = true
              end
              sleep 0.1 unless processed
            end
          end

          private

          def inner_process
            filename = uri_to_file(params['textDocument']['uri'])
            line = params['position']['line']
            col = params['position']['character']
            begin
              completion = host.completions_at(filename, line, col)
              if host.cancel?(id)
                return set_result(empty_result) if host.cancel?(id)
              end
              items = []
              idx = 0
              completion.pins.each do |pin|
                items.push pin.completion_item.merge({
                  textEdit: {
                    range: completion.range.to_hash,
                    newText: pin.name
                  },
                  sortText: "#{pin.name}#{idx.to_s.rjust(4, '0')}"
                })
                idx += 1
              end
              set_result(
                isIncomplete: false,
                items: items
              )
            rescue InvalidOffsetError => e
              STDERR.puts "Skipping invalid offset: #{filename}, line #{line}, character #{col}"
              set_result empty_result
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
