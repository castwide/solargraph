# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class BlockNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            # s(:block, call, args, body)
            return process_children unless node in [:block, call, *]

            location = get_node_location(node)
            scope = region.scope || region.closure.context.scope
            # Foo.class_eval { ... } - s(:send, s(:const, ...), :class_eval, *args)
            if call in [:send, [:cbase | :const, *] => clazz, :class_eval, *]
              clazz_name = unpack_name(clazz)
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
              receiver: call,
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
