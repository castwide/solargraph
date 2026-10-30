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
            # s(:rescue, body, *resbody, else) or s(:ensure, body, ensure_body);
            # body, else and ensure_body are nil when absent
            node => [:rescue | :ensure, ::Parser::AST::Node | nil => body_node, *]
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
            node.children.drop(1).each do |child|
              next unless child in ::Parser::AST::Node => clause_node

              NodeProcessor.process(clause_node, region, pins, locals, ivars)
            end
          end
        end
      end
    end
  end
end
