# frozen_string_literal: true

module Solargraph
  module Parser
    module Legacy
      module NodeProcessor
        class ArgsNode < Base
          def process
            node.children.each do |u|
              loc = get_node_location(u)
              locals.push Solargraph::Pin::Parameter.new(
                location: loc,
                closure: region.closure,
                comments: comments_for(node),
                name: u.children[0].to_s,
                assignment: u.children[1],
                presence: region.closure.location.range
              )
            end
            process_children
          end
        end
      end
    end
  end
end
