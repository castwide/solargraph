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

          # Blocks written with implicit parameters carry no args node for
          # ArgsNode to work from, so their parameter pins are synthesized
          # here instead. A numblock is a regular block that has no args
          # node - it stores its highest numbered parameter where an
          # ordinary block stores that node instead (see
          # #numbered_parameter_count).
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

          # A numblock stores the highest numbered parameter its body uses
          # (2 for `_2`) where an ordinary block stores its args node, e.g.
          # `[1, 2].each { _1 + _2 }` parses as:
          #
          #   s(:numblock,
          #     s(:send, s(:array, s(:int, 1), s(:int, 2)), :each),
          #     2,
          #     s(:send, s(:lvar, :_1), :+, s(:lvar, :_2)))
          #
          # @sg-ignore flow sensitive typing does not narrow the return value through the is_a? guard
          # @return [Integer]
          def numbered_parameter_count
            count = node.children[1]
            return 0 unless count.is_a?(::Integer)

            count
          end

          # An `it` block reaches us as an ordinary block with an empty args
          # node, so the node itself records nothing about the parameter and
          # the only available signal is an `it` reference in the body.
          #
          # Mixing `it` with ordinary parameters is a syntax error, so an
          # empty args node is a precondition rather than a guess. A local
          # variable named `it` in an enclosing scope does take precedence
          # over the implicit parameter, and is parsed identically, so it has
          # to be excluded here.
          #
          # @return [Boolean]
          def implicit_it_parameter?
            args = node.children[1]
            return false unless Parser.is_ast_node?(args)
            # @sg-ignore tool-limitation:is_a-narrowing:predicate-wrapper -
            #   flow-sensitive typing only recognizes a literal is_a? call
            #   on the guarded variable, not one wrapped in a helper
            #   predicate method like Parser.is_ast_node? above. No
            #   upstream issue filed yet.
            return false unless args.type == :args && args.children.empty?
            return false if shadowed_it_local?
            references_it?(node.children[2])
          end

          # Only a local variable declared outside any block shadows the
          # implicit parameter. A block's own `it` must not stop a nested
          # block from having one: in `xs.map { it.map { it.upcase } }` each
          # `it` belongs to the block it appears in.
          #
          # This diverges from Ruby for an enclosing block with an explicit
          # parameter named `it`. In `xs.map { |it| ys.map { it } }` Ruby
          # reads the inner `it` as the outer parameter; this gives the
          # inner block its own. Treating a block parameter as a shadow
          # instead would break every nested implicit `it`, which is the
          # far more common shape.
          #
          # @return [Boolean]
          def shadowed_it_local?
            loc = get_node_location(node)
            locals.any? do |pin|
              pin.name == 'it' && !pin.closure.is_a?(Pin::Block) && pin.visible_at?(region.closure, loc)
            end
          end

          # `it` inside a nested block belongs to that block, so the search
          # skips a nested block's body. Its receiver and arguments are still
          # searched, since those sit in the enclosing block: the `it` in
          # `xs.map { it.map { |y| y } }` is the outer block's parameter.
          #
          # @param subject [BasicObject, nil]
          # @return [Boolean]
          def references_it? subject
            return false unless Parser.is_ast_node?(subject)
            # @sg-ignore tool-limitation:is_a-narrowing:predicate-wrapper -
            #   same Parser.is_ast_node? gap as in #implicit_it_parameter?
            return true if subject.type == :lvar && subject.children[0] == :it
            # @sg-ignore tool-limitation:is_a-narrowing:predicate-wrapper
            children = if %i[block numblock].include?(subject.type)
                         # @sg-ignore tool-limitation:is_a-narrowing:predicate-wrapper
                         subject.children[0..1]
                       else
                         # @sg-ignore tool-limitation:is_a-narrowing:predicate-wrapper
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
