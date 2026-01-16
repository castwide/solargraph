# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class WhenNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            pins.push Solargraph::Pin::CompoundStatement.new(
              location: get_node_location(node),
              closure: region.closure,
              node: node,
              source: :parser,
            )
            process_children
          end
        end
      end
    end
  end
end
