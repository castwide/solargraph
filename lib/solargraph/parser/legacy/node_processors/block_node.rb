# frozen_string_literal: true

module Solargraph
  module Parser
    module Legacy
      module NodeProcessors
        class BlockNode < Parser::NodeProcessor::Base
          include Legacy::NodeMethods

          def process
            if other_class_eval?
              other_class = Solargraph::Pin::Namespace.new(
                type: :class,
                name: unpack_name(node.children[0].children[0])
              )
              make_block_in other_class.context
              process_children region.update(closure: other_class)
            else
              make_block_in nil
              process_children region.update(closure: pins.last)
            end
          end

          private

          def other_class_eval?
            node.children[0].type == :send &&
              node.children[0].children[1] == :class_eval &&
              [:cbase, :const].include?(node.children[0].children[0]&.type)
          end

          def make_block_in context
            pins.push Solargraph::Pin::Block.new(
              location: get_node_location(node),
              context: context,
              closure: region.closure,
              receiver: node.children[0],
              comments: comments_for(node),
              scope: region.scope || region.closure.context.scope
            )
          end
        end
      end
    end
  end
end
