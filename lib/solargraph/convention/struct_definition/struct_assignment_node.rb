# frozen_string_literal: true

module Solargraph
  module Convention
    module StructDefinition
      # A node wrapper for a Struct definition via const assignment.
      # @example
      #   MyStruct = Struct.new(:bar, :baz) do
      #     def foo
      #     end
      #   end
      class StructAssignmentNode < StructDefintionNode
        class << self
          # @example
          # s(:casgn, nil, :Foo,
          #   s(:block,
          #     s(:send,
          #       s(:const, nil, :Struct), :new,
          #       s(:sym, :bar),
          #       s(:sym, :baz)),
          #     s(:args),
          #     s(:def, :foo,
          #       s(:args),
          #       s(:send, nil, :bar))))
          def match?(node)
            return false unless node&.type == :casgn
            return false if node.children[2].nil?

            struct_node = if node.children[2].type == :block
                            node.children[2].children[0]
                          else
                            node.children[2]
                          end

            struct_definition_node?(struct_node)
          end
        end

        def class_name
          if node.children[0]
            Parser::NodeMethods.unpack_name(node.children[0]) + "::#{node.children[1]}"
          else
            node.children[1].to_s
          end
        end

        private

        # @return [Parser::AST::Node]
        def struct_node
          if node.children[2].type == :block
            node.children[2].children[0]
          else
            node.children[2]
          end
        end
      end
    end
  end
end
