# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class OrasgnNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          # @return [void]
          def process
            closure_location = region.closure.location
            if closure_location
              here = get_node_start_position(node)
              presence = Range.new(here, closure_location.range.ending)
              FlowSensitiveTyping.new(locals, ivars, enclosing_breakable_pin,
                                      enclosing_compound_statement_pin).process_or_asgn(node, presence)
            end

            new_node = node.updated(node.children[0].type, node.children[0].children + [node.children[1]])
            NodeProcessor.process(new_node, region, pins, locals, ivars)
          end
        end
      end
    end
  end
end
