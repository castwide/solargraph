# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class WhileNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            flow_sensitive_typing = FlowSensitiveTyping.new(locals,
                                                            ivars,
                                                            enclosing_breakable_pin,
                                                            enclosing_compound_statement_pin)

            # Note - this should not be considered a block, as the
            # while statement doesn't create a closure - e.g.,
            # variables created inside can be seen from outside as
            # well
            while_pin = Solargraph::Pin::While.new(
              location: location,
              closure: region.closure,
              compound_statement: region.compound_statement,
              conditional: true,
              node: node,
              comments: comments_for(node),
              source: :parser
            )
            pins.push while_pin
            while_region = region.update(compound_statement: while_pin)
            condition_node, body_node = node.children
            # before narrowing, so that a variable the condition itself
            # assigns (`while (line = gets)`) already has a pin
            NodeProcessor.process(condition_node, while_region, pins, locals, ivars)
            flow_sensitive_typing.process_while(node)
            NodeProcessor.process(body_node, while_region, pins, locals, ivars)
            true
          end
        end
      end
    end
  end
end
