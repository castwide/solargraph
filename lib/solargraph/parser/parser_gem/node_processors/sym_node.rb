# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class SymNode < Parser::NodeProcessor::Base
          on_node_type :sym, :process

          # @!method node
          #   @return [RuboCop::AST::SymbolNode]

          # @return [void]
          def process
            pins.push Solargraph::Pin::Symbol.new(
              get_node_location(node),
              ":#{node.value}",
              source: :parser
            )
          end
        end
      end
    end
  end
end
