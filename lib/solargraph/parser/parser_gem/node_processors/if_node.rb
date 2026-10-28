# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class IfNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            condition_node = node.children[0]
            # built before the condition adds its pins: a ternary's
            # condition starts where the if does, so its own compound
            # statement would otherwise be taken as the enclosing one
            flow_sensitive_typing = FlowSensitiveTyping.new(locals,
                                                            ivars,
                                                            enclosing_breakable_pin,
                                                            enclosing_compound_statement_pin)
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
            # after the condition, so that a variable the condition
            # itself assigns (`if (md = foo.match(...))`) already has a
            # pin to assert facts about
            flow_sensitive_typing.process_if(node)
            then_node = node.children[1]
            if then_node
              then_cs = Solargraph::Pin::CompoundStatement.new(
                location: get_node_location(then_node),
                closure: region.closure,
                compound_statement: region.compound_statement,
                conditional: true,
                node: then_node,
                source: :parser
              )
              pins.push then_cs
              NodeProcessor.process(then_node, region.update(compound_statement: then_cs), pins, locals, ivars)
              start_modifier_assignment_after_if(then_node, condition_node)
            end

            else_node = node.children[2]
            if else_node
              else_cs = Solargraph::Pin::CompoundStatement.new(
                location: get_node_location(else_node),
                closure: region.closure,
                compound_statement: region.compound_statement,
                conditional: true,
                node: else_node,
                source: :parser
              )
              pins.push else_cs
              NodeProcessor.process(else_node, region.update(compound_statement: else_cs), pins, locals, ivars)
              start_modifier_assignment_after_if(else_node, condition_node)
            end

            true
          end

          private

          # The assignment in 'x = nil if x.empty?' runs after the
          # condition that follows it, so x keeps its earlier value there
          #
          # @param branch_node [Parser::AST::Node]
          # @param condition_node [Parser::AST::Node, nil]
          #
          # @return [void]
          def start_modifier_assignment_after_if branch_node, condition_node
            return unless branch_node.type == :lvasgn && condition_node
            return unless branch_node.loc.expression.end_pos <= condition_node.loc.expression.begin_pos

            name = branch_node.children[0].to_s
            assignment_start = get_node_start_position(branch_node)
            after_if = get_node_end_position(node)
            locals.map! do |pin|
              presence = pin.presence
              next pin unless pin.name == name && presence && presence.start == assignment_start

              pin.with_presence(Range.new(after_if, presence.ending))
            end
          end
        end
      end
    end
  end
end
