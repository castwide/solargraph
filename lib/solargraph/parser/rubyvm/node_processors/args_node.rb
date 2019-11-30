# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        class ArgsNode < Parser::NodeProcessor::Base
          def process
            # node.children.each do |u|
            #   loc = get_node_location(u)
            #   locals.push Solargraph::Pin::Parameter.new(
            #     location: loc,
            #     closure: region.closure,
            #     comments: comments_for(node),
            #     name: u.children[0].to_s,
            #     assignment: u.children[1],
            #     presence: region.closure.location.range
            #   )
            # end
            node.children[0].times do |i|
              locals.push Solargraph::Pin::Parameter.new(
                location: region.closure.location,
                closure: region.closure,
                comments: comments_for(node),
                name: region.lvars[i].to_s,
                presence: region.closure.location.range
              )
            end
            # @todo Optional args, keyword args, etc.
            if node.children.last
              locals.push Solargraph::Pin::Parameter.new(
                location: region.closure.location,
                closure: region.closure,
                comments: comments_for(node),
                name: node.children.last.to_s,
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
