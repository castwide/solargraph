# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class IfNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            FlowSensitiveTyping.new(locals,
                                    ivars,
                                    enclosing_breakable_pin,
                                    enclosing_compound_statement_pin).process_if(node)
            condition_node = node.children[0]
            if condition_node
              pins.push Solargraph::Pin::CompoundStatement.new(
                location: get_node_location(condition_node),
                closure: region.closure,
                compound_statement: region.compound_statement,
                node: condition_node,
                source: :parser
              )
              NodeProcessor.process(condition_node, region, pins, locals, ivars)
            end
            then_node = node.children[1]
            if then_node
              # @sg-ignore Need to add nil check here
              then_cs = Solargraph::Pin::CompoundStatement.new(
                location: get_node_location(then_node),
                closure: region.closure,
                compound_statement: region.compound_statement,
                node: then_node,
                source: :parser
              )
              pins.push then_cs
              # @sg-ignore Need to add nil check here
              NodeProcessor.process(then_node, region.update(compound_statement: then_cs, conditional: true), pins, locals, ivars)
            end

            else_node = node.children[2]
            if else_node
              # @sg-ignore Need to add nil check here
              else_cs = Solargraph::Pin::CompoundStatement.new(
                location: get_node_location(else_node),
                closure: region.closure,
                compound_statement: region.compound_statement,
                node: else_node,
                source: :parser
              )
              pins.push else_cs
              # @sg-ignore Need to add nil check here
              NodeProcessor.process(else_node, region.update(compound_statement: else_cs, conditional: true), pins, locals, ivars)
            end

            true
          end
        end
      end
    end
  end
end
