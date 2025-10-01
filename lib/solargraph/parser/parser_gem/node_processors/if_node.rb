# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class IfNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            process_children

            FlowSensitiveTyping.new(locals,
                                    enclosing_breakable_pin,
                                    enclosing_compound_statement_pin).process_if(node)

            pins.push Solargraph::Pin::If.new(
              location: get_node_location(node),
              closure: region.closure,
              node: node,
              comments: comments_for(node),
              source: :parser,
            )
            process_children region
          end
        end
      end
    end
  end
end
