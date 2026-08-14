# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class OrasgnNode < Parser::NodeProcessor::Base
          # @return [void]
          def process
            new_node = node.updated(node.children[0].type, node.children[0].children + [node.children[1]])
            # `x ||= y` only assigns when x is falsy/undefined, so
            # it's never a guaranteed override of x's prior type
            NodeProcessor.process(new_node, region.update(conditional_boundary: Range.from_node(node)), pins, locals, ivars)
          end
        end
      end
    end
  end
end
