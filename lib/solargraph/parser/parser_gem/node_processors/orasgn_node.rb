# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class OrasgnNode < Parser::NodeProcessor::Base
          # @return [void]
          def process
            FlowSensitiveTyping.new(expression_types,
                                    ivars,
                                    enclosing_breakable_pin,
                                    enclosing_compound_statement_pin).process_index_or_asgn(node)
            new_node = node.updated(node.children[0].type, node.children[0].children + [node.children[1]])
            NodeProcessor.process(new_node, region, pins, expression_types, ivars)
          end
        end
      end
    end
  end
end
