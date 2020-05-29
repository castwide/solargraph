# frozen_string_literal: true

module Solargraph
  module Parser
    module Legacy
      module NodeProcessors
        class SclassNode < Parser::NodeProcessor::Base
          def process
            # @todo Temporarily skipping remote metaclasses
            return unless node.children[0].is_a?(AST::Node) && node.children[0].type == :self
            pins.push Solargraph::Pin::Singleton.new(
              location: get_node_location(node),
              closure: region.closure
            )
            process_children region.update(visibility: :public, scope: :class, closure: pins.last)
          end
        end
      end
    end
  end
end
