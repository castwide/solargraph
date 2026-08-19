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
            add_numbered_parameters block_pin if node.type == :numblock
            process_children region.update(closure: block_pin)
          end

          private

          # A numblock node stores the highest numbered parameter used in
          # its body (e.g., 2 for `_2`) instead of an args node, so the
          # parameter pins have to be synthesized here.
          #
          # @param block_pin [Pin::Block]
          # @return [void]
          def add_numbered_parameters block_pin
            count = node.children[1]
            return unless count.is_a?(::Integer)

            (1..count).each do |number|
              locals.push Solargraph::Pin::Parameter.new(
                location: block_pin.location,
                closure: block_pin,
                name: "_#{number}",
                # @sg-ignore Need to add nil check here
                presence: block_pin.location.range,
                decl: :arg,
                source: :parser
              )
              block_pin.parameters.push locals.last
            end
          end

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
