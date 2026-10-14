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
              # @sg-ignore child node types depend on parent node type
              pins.push Solargraph::Pin::CompoundStatement.new(
                # @sg-ignore child node types depend on parent node type
                location: get_node_location(condition_node),
                closure: region.closure,
                node: condition_node,
                source: :parser
              )
              # @sg-ignore child node types depend on parent node type
              NodeProcessor.process(condition_node, region, pins, locals, ivars)
            end
            then_node = node.children[1]
            if then_node
              # @sg-ignore child node types depend on parent node type
              pins.push Solargraph::Pin::CompoundStatement.new(
                # @sg-ignore child node types depend on parent node type
                location: get_node_location(then_node),
                closure: region.closure,
                node: then_node,
                source: :parser
              )
              # @sg-ignore child node types depend on parent node type
              NodeProcessor.process(then_node, region, pins, locals, ivars)
            end

            else_node = node.children[2]
            if else_node
              # @sg-ignore child node types depend on parent node type
              pins.push Solargraph::Pin::CompoundStatement.new(
                # @sg-ignore child node types depend on parent node type
                location: get_node_location(else_node),
                closure: region.closure,
                node: else_node,
                source: :parser
              )
              # @sg-ignore child node types depend on parent node type
              NodeProcessor.process(else_node, region, pins, locals, ivars)
            end

            true
          end
        end
      end
    end
  end
end
