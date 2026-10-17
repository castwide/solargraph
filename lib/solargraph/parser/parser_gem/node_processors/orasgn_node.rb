# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class OrasgnNode < Parser::NodeProcessor::Base
          # @return [void]
          def process
            new_node = node.updated(node.children.fetch(0).type, node.children.fetch(0).children + [node.children.fetch(1)])
            NodeProcessor.process(new_node, region, pins, locals, ivars)
          end
        end
      end
    end
  end
end
