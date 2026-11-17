# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class OrasgnNode < Parser::NodeProcessor::Base
          # @return [void]
          def process
            new_node = node.updated(node.children[0].type, node.children[0].children + [node.children[1]])
            # `x ||= y` assigns only when x is falsy, so it never overrides
            # x's prior type.
            asgn_cs = Solargraph::Pin::CompoundStatement.new(
              location: get_node_location(node),
              closure: region.closure,
              compound_statement: region.compound_statement,
              conditional: true,
              node: node,
              source: :parser
            )
            pins.push asgn_cs
            NodeProcessor.process(new_node, region.update(compound_statement: asgn_cs), pins, locals, ivars)
          end
        end
      end
    end
  end
end
