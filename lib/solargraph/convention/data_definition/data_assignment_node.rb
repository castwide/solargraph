# frozen_string_literal: true

module Solargraph
  module Convention
    module DataDefinition
      # A node wrapper for a Data definition via const assignment.
      # @example
      #   MyData = Data.new(:bar, :baz) do
      #     def foo
      #     end
      #   end
      class DataAssignmentNode < DataDefintionNode
        class << self
          # @example
          # s(:casgn, nil, :Foo,
          #   s(:block,
          #     s(:send,
          #       s(:const, nil, :Data), :define,
          #       s(:sym, :bar),
          #       s(:sym, :baz)),
          #     s(:args),
          #     s(:def, :foo,
          #       s(:args),
          #       s(:send, nil, :bar))))
          # @param node [::Parser::AST::Node]
          def match? node
            return false unless node&.type == :casgn
            assignment_node = node.children[2]
            return false if assignment_node.nil?

            data_node = if assignment_node.type == :block
                          assignment_node.children[0]
                        else
                          assignment_node
                        end

            # @sg-ignore Need to add nil check here
            data_definition_node?(data_node)
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
        def data_node
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
