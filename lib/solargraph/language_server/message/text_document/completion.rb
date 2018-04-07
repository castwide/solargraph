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
                if host.changing?(params['textDocument']['uri'])
                  if Time.now - start > 1
                    set_error Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, 'Completion request timed out'
                    processed = true
                  end
                else
                  inner_process
                  processed = true
                end
                sleep 0.1 unless processed
              end
            rescue Exception => e
              STDERR.puts "Error in textDocument/completion: #{e.message}"
              # Ignore 'Invalid offset' errors, since they usually just mean
              # that the document is in the process of changing.
              if e.message.include?('Invalid offset')
                # @todo Should this result be marked as incomplete? It might
                #   be possible to resolve it after changes are finished.
                set_result empty_result
              else
                set_error ErrorCodes::INTERNAL_ERROR, e.message
              end
            end
          end

          private

          def inner_process
            filename = uri_to_file(params['textDocument']['uri'])
            line = params['position']['line']
            col = params['position']['character']
            completion = host.completions_at(filename, line, col)
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
