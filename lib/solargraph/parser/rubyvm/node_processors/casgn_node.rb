# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        class CasgnNode < Parser::NodeProcessor::Base
          def process
            pins.push Solargraph::Pin::Constant.new(
              location: get_node_location(node),
              closure: region.closure,
              name: node.children[0].to_s,
              comments: comments_for(node),
              assignment: node.children[1]
            )
            process_children
          end
        end
      end
    end
  end
end
