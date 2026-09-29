# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        # Offers the code lenses on the requested lines as source actions, so
        # clients can run their commands without rendering the lenses, e.g.
        # from a test explorer.
        class CodeAction < Base
          KIND = 'source'

          def process
            return set_result([]) unless kind_requested?

            first_line = params['range']['start']['line']
            last_line = params['range']['end']['line']
            lenses = host.code_lenses(params['textDocument']['uri']).select do |lens|
              lens.range.start.line.between?(first_line, last_line)
            end
            set_result(lenses.map { |lens| { title: lens.command.title, kind: KIND, command: lens.command.to_hash } })
          end

          private

          # @return [Boolean]
          def kind_requested?
            # @type [Array<String>, nil]
            only = params.dig('context', 'only')
            return true if only.nil?

            only.any? { |kind| KIND.eql?(kind) || KIND.start_with?("#{kind}.") }
          end
        end
      end
    end
  end
end
