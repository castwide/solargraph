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
          #
          # @param node [Parser::AST::Node]
          def match? node
            return false unless node&.type == :casgn
            assignment_node = node.children[2]
            return false if assignment_node.nil?

            struct_node = if assignment_node.type == :block
                            assignment_node.children[0]
                          else
                            assignment_node
                          end

            # @sg-ignore Need to add nil check here
            struct_definition_node?(struct_node)
          end
        end

        def class_name
          namespace_node = node.children[0]
          if namespace_node
            Parser::NodeMethods.unpack_name(namespace_node) + "::#{node.children[1]}"
          else
            node.children[1].to_s
          end
        end

        private

        # @return [Parser::AST::Node]
        # @sg-ignore Need to add nil check here
        def struct_node
          assignment_node = node.children[2]
          # @sg-ignore Need to add nil check here
          if assignment_node.type == :block
            # @sg-ignore Need to add nil check here
            assignment_node.children[0]
          else
            assignment_node
          end
        end
      end
    end
  end
end
