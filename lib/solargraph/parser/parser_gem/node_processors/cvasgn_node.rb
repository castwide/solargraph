# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class CvasgnNode < Parser::NodeProcessor::Base
          def process
            loc = get_node_location(node)
            pin = Solargraph::Pin::ClassVariable.new(
              location: loc,
              closure: region.closure,
              name: node.children[0].to_s,
              comments: comments_for(node),
              assignment: node.children[1]
            )
            logger.debug { "CvasgnNode#process() - pin=#{pin}" }
            pins.push pin
            process_children
          end

          include Logging
        end
      end
    end
  end
end
