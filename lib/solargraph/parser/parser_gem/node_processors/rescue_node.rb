# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        # The protected body of a rescue or ensure, which may stop at
        # any statement, so an assignment in it is definite only within
        # the body itself - not in a rescue or ensure clause, or after.
        class RescueNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          # @return [void]
          def process
            body_node = node.children[0]
            if body_node
              body_cs = Solargraph::Pin::CompoundStatement.new(
                location: get_node_location(body_node),
                closure: region.closure,
                compound_statement: region.compound_statement,
                conditional: true,
                node: body_node,
                source: :parser
              )
              pins.push body_cs
              NodeProcessor.process(body_node, region.update(compound_statement: body_cs), pins, locals, ivars)
            end
            node.children.drop(1).each do |clause_node|
              NodeProcessor.process(clause_node, region, pins, locals, ivars)
            end
          end
        end
      end
    end
  end
end
