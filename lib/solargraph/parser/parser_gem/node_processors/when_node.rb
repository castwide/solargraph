# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class WhenNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          on_node_type :when, :process

          # @return [void]
          def process
            pins.push Solargraph::Pin::CompoundStatement.new(
              location: get_node_location(node),
              closure: region.closure,
              node: node,
              source: :parser
            )
          end
        end
      end
    end
  end
end
