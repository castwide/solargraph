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
            process_children region.update(closure: block_pin)
          end

          private

          def other_class_eval?
            node.children[0].type == :send &&
              node.children[0].children[1] == :class_eval &&
              # @sg-ignore Need to add nil check here
              [:cbase, :const].include?(node.children[0].children[0]&.type)
          end
        end
      end
    end
  end
end
