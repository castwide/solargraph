# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class LvasgnNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            # variable not visible until next statement
            presence = Range.new(get_node_end_position(node), region.closure.location.range.ending)
            loc = get_node_location(node)
            locals.push Solargraph::Pin::LocalVariable.new(
              location: loc,
              closure: region.closure,
              name: node.children[0].to_s,
              assignment: node.children[1],
              comments: comments_for(node),
              presence: presence
            )
            process_children
          end
        end
      end
    end
  end
end
