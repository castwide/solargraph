# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class WhileNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            FlowSensitiveTyping.new(locals,
                                    enclosing_breakable_pin,
                                    enclosing_compound_statement_pin).process_while(node)

            # Note - this should not be considered a block, as the
            # while statement doesn't create a closure - e.g.,
            # variables created inside can be seen from outside as
            # well
            pins.push Solargraph::Pin::While.new(
              location: location,
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
