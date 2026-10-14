# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class SymNode < Parser::NodeProcessor::Base
          # @return [void]
          def process
            return unless node in [:sym, value]

            pins.push Solargraph::Pin::Symbol.new(
              get_node_location(node),
              ":#{value}",
              source: :parser
            )
          end
        end
      end
    end
  end
end
