# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class WhenNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            cs = Solargraph::Pin::CompoundStatement.new(
              location: get_node_location(node),
              closure: region.closure,
              compound_statement: region.compound_statement,
              node: node,
              source: :parser
            )
            pins.push cs
            process_children region.update(compound_statement: cs, conditional: true)
          end
        end
      end
    end
  end
end
