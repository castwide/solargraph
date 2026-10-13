# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class IfNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          on_node_pattern_enter '(if $_ $_ $_)', :process

          # @param condition_node [::Parser::AST::Node, nil]
          # @param then_node [::Parser::AST::Node, nil]
          # @param else_node [::Parser::AST::Node, nil]
          # @return [void]
          def process condition_node, then_node, else_node
            skip_children
            FlowSensitiveTyping.new(locals,
                                    ivars,
                                    enclosing_breakable_pin,
                                    enclosing_compound_statement_pin).process_if(node)
            if condition_node
              pins.push Solargraph::Pin::CompoundStatement.new(
                location: get_node_location(condition_node),
                closure: region.closure,
                node: condition_node,
                source: :parser
              )
              walk(condition_node)
            end
            if then_node
              pins.push Solargraph::Pin::CompoundStatement.new(
                location: get_node_location(then_node),
                closure: region.closure,
                node: then_node,
                source: :parser
              )
              walk(then_node)
            end

            return unless else_node
            pins.push Solargraph::Pin::CompoundStatement.new(
              location: get_node_location(else_node),
              closure: region.closure,
              node: else_node,
              source: :parser
            )
            walk(else_node)
          end
        end
      end
    end
  end
end
