# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class IfNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            FlowSensitiveTyping.new(locals,
                                    enclosing_breakable_pin,
                                    enclosing_compound_statement_pin).process_if(node)
            condition_node = node.children[0]
            if condition_node
              pins.push Solargraph::Pin::CompoundStatement.new(
                location: get_node_location(condition_node),
                closure: region.closure,
                node: condition_node,
                source: :parser,
              )
              NodeProcessor.process(condition_node, region, pins, locals)
            end
            then_node = node.children[1]
            if then_node
              pins.push Solargraph::Pin::CompoundStatement.new(
                location: get_node_location(then_node),
                closure: region.closure,
                node: then_node,
                source: :parser,
              )
              NodeProcessor.process(then_node, region, pins, locals)
            end

            else_node = node.children[2]
            if else_node
              pins.push Solargraph::Pin::CompoundStatement.new(
                location: get_node_location(else_node),
                closure: region.closure,
                node: else_node,
                source: :parser,
              )
              NodeProcessor.process(else_node, region, pins, locals)
            end

            true
          end
        end
      end
    end
  end
end
