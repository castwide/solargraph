# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class AndNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            # the rhs of `a && b` only executes if `a` is truthy, so
            # any assignment there isn't guaranteed to have executed
            lhs, rhs = node.children
            NodeProcessor.process(lhs, region, pins, locals, ivars)
            NodeProcessor.process(rhs, region.update(conditional: true), pins, locals, ivars)

            FlowSensitiveTyping.new(locals,
                                    ivars,
                                    enclosing_breakable_pin,
                                    enclosing_compound_statement_pin).process_and(node)
          end
        end
      end
    end
  end
end
