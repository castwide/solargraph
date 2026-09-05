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
            add_implicit_parameters block_pin
            process_children region.update(closure: block_pin)
          end

          private

          # Numblocks and `it` blocks have no args node for ArgsNode to work from.
          #
          # @param block_pin [Pin::Block]
          # @return [void]
          def add_implicit_parameters block_pin
            if node.type == :numblock
              numbered_parameter_count.times { |idx| add_implicit_parameter block_pin, "_#{idx + 1}" }
            elsif implicit_it_parameter?
              add_implicit_parameter block_pin, 'it'
            end
          end

          # A numblock stores its highest numbered parameter (2 for `_2`) where a block stores its args node.
          #
          # @sg-ignore flow sensitive typing needs to narrow down type with an if is_a? check
          # @return [Integer]
          def numbered_parameter_count
            count = node.children[1]
            return 0 unless count.is_a?(::Integer)

            count
          end

          # An `it` block parses as an ordinary block with an empty args node, so the only
          # signal is an `it` reference in the body. Mixing `it` with named parameters is a
          # syntax error, so the empty args node is a precondition rather than a guess.
          #
          # @return [Boolean]
          def implicit_it_parameter?
            args = node.children[1]
            return false unless Parser.is_ast_node?(args)
            # @sg-ignore flow sensitive typing needs to narrow through a predicate method like Parser.is_ast_node?
            return false unless args.type == :args && args.children.empty?
            return false if shadowed_it_local?
            references_it?(node.children[2])
          end

          # Only a local declared outside any block shadows the implicit parameter, so a
          # nested block still gets its own. A synthesized `it` is indistinguishable from an
          # explicit `|it|`, so an outer `|it|` does not shadow either, unlike in Ruby.
          #
          # @return [Boolean]
          def shadowed_it_local?
            loc = get_node_location(node)
            locals.any? do |pin|
              pin.name == 'it' && !pin.closure.is_a?(Pin::Block) && pin.visible_at?(region.closure, loc)
            end
          end

          # Skips a nested block's body, whose `it` belongs to that block, but still searches
          # its receiver and arguments: those sit in the enclosing block.
          #
          # @param subject [BasicObject, nil]
          # @return [Boolean]
          def references_it? subject
            return false unless Parser.is_ast_node?(subject)
            # @sg-ignore flow sensitive typing needs to narrow through a predicate method like Parser.is_ast_node?
            return true if subject.type == :lvar && subject.children[0] == :it
            # @sg-ignore flow sensitive typing needs to narrow through a predicate method like Parser.is_ast_node?
            children = if %i[block numblock].include?(subject.type)
                         # @sg-ignore flow sensitive typing needs to narrow through a predicate method like Parser.is_ast_node?
                         subject.children[0..1]
                       else
                         # @sg-ignore flow sensitive typing needs to narrow through a predicate method like Parser.is_ast_node?
                         subject.children
                       end
            children.any? { |child| references_it?(child) }
          end

          # @param block_pin [Pin::Block]
          # @param name [String]
          # @return [void]
          def add_implicit_parameter block_pin, name
            locals.push Solargraph::Pin::Parameter.new(
              location: block_pin.location,
              closure: block_pin,
              name: name,
              # @sg-ignore Need to add nil check here
              presence: block_pin.location.range,
              decl: :arg,
              source: :parser
            )
            block_pin.parameters.push locals.last
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
