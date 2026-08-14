# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class OrasgnNode < Parser::NodeProcessor::Base
          # @return [void]
          def process
            new_node = node.updated(node.children[0].type, node.children[0].children + [node.children[1]])
            # `x ||= y` only assigns when x is falsy/undefined, so
            # it's never a guaranteed override of x's prior type
            #
            # not pushed onto `pins` - see resbody_node.rb for why
            asgn_cs = Solargraph::Pin::CompoundStatement.new(
              location: get_node_location(node),
              closure: region.closure,
              compound_statement: region.compound_statement,
              conditional: true,
              node: node,
              source: :parser
            )
            NodeProcessor.process(new_node, region.update(compound_statement: asgn_cs), pins, locals, ivars)
          end
        end
      end
    end
  end
end
