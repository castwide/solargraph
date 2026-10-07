# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class GvasgnNode < Parser::NodeProcessor::Base
          on_node_type :gvasgn, :process

          # @!method node
          #   @return [RuboCop::AST::AsgnNode]

          # @return [void]
          def process
            loc = get_node_location(node)
            pins.push Solargraph::Pin::GlobalVariable.new(
              location: loc,
              closure: region.closure,
              name: node.name.to_s,
              comments: comments_for(node),
              assignment: node.expression,
              source: :parser
            )
          end
        end
      end
    end
  end
end
