require 'time'

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class Completion < Base
          def process
            inner_process
          end

          private

          # @return [void]
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
              last_context = nil
              idx = -1
              completion.pins.each do |pin|
                idx += 1 if last_context != pin.context
                items.push pin.completion_item.merge({
                  textEdit: {
                    range: completion.range.to_hash,
                    newText: pin.name.sub(/=$/, ' = ')
                  },
                  sortText: "#{idx.to_s.rjust(4, '0')}#{pin.name}"
                })
                items.last[:data][:uri] = params['textDocument']['uri']
                last_context = pin.context
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

          # @param incomplete [Boolean]
          # @return [Hash]
          def empty_result incomplete = false
            {
              isIncomplete: incomplete,
              items: []
            }
          end
        end
      end
    end
  end
end
