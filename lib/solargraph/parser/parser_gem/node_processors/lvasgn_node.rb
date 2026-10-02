# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class LvasgnNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          on_node_type :lvasgn, :process

          # @!method node
          #   @return [RuboCop::AST::AsgnNode]

          # @return [void]
          def process
            here = get_node_start_position(node)
            # @sg-ignore Need to add nil check here
            presence = Range.new(here, region.closure.location.range.ending)
            loc = get_node_location(node)
            locals.push Solargraph::Pin::LocalVariable.new(
              location: loc,
              closure: region.closure,
              name: node.name.to_s,
              assignment: node.expression,
              comments: comments_for(node),
              presence: presence,
              source: :parser
            )
          end
        end
      end
    end
  end
end
