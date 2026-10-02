# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class BlockNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          on_node_type :block, :process

          # @!method node
          #   @return [RuboCop::AST::BlockNode]

          # @!method class_eval_receiver(node)
          #   @param node [::Parser::AST::Node]
          #   @return [::Parser::AST::Node, nil]
          def_node_matcher :class_eval_receiver, '(block (send ${cbase const} :class_eval ...) ...)'

          # @return [void]
          def process
            location = get_node_location(node)
            scope = region.scope || region.closure.context.scope
            evaluated_class = class_eval_receiver(node)
            if evaluated_class
              clazz_name = unpack_name(evaluated_class)
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
              receiver: node.send_node,
              comments: comments_for(node),
              scope: scope,
              source: :parser
            )
            pins.push block_pin
            process_children region.update(closure: block_pin)
          end
        end
      end
    end
  end
end
