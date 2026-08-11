# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class BlockNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            location = get_node_location(node)
            scope = region.scope || region.closure.context.scope
            if other_class_eval?
              clazz_name = unpack_name(node.children[0].children[0])
              # instance variables should come from the Class<T> type
              # - i.e., treated as class instance variables
              context = ComplexType.try_parse("Class<#{clazz_name}>")
              scope = :class
            end
            block_pin = Solargraph::Pin::Block.new(
              location: location,
              closure: region.closure,
              node: node,
              context: context,
              receiver: node.children[0],
              comments: comments_for(node),
              scope: scope,
              source: :parser
            )
            pins.push block_pin
            # a block's body may execute zero or multiple times (e.g.
            # Enumerable#each), so an assignment inside it is never
            # guaranteed to have executed
            process_children region.update(closure: block_pin, conditional: true)
          end

          private

          def other_class_eval?
            node.children[0].type == :send &&
              node.children[0].children[1] == :class_eval &&
              %i[cbase const].include?(node.children[0].children[0]&.type)
          end
        end
      end
    end
  end
end
