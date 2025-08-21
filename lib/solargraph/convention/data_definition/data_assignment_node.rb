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
          def match?(node)
            return false unless node&.type == :casgn
            return false if node.children[2].nil?

            data_node = if node.children[2].type == :block
                          node.children[2].children[0]
                        else
                          node.children[2]
                        end

            data_definition_node?(data_node)
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
        def data_node
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
