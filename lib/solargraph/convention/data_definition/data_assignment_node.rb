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
            return false if node.children[2].nil?

            # @sg-ignore https://github.com/castwide/solargraph/pull/1245
            data_node = if node.children[2].type == :block
                          # @sg-ignore https://github.com/castwide/solargraph/pull/1245
                          node.children[2].children[0]
                        else
                          node.children[2]
                        end

            # @sg-ignore Need to add nil check here
            data_definition_node?(data_node)
          end
        end

        def class_name
          if node.children[0]
            # @sg-ignore https://github.com/castwide/solargraph/pull/1245
            Parser::NodeMethods.unpack_name(node.children[0]) + "::#{node.children[1]}"
          else
            node.children[1].to_s
          end
        end

        private

        # @return [Parser::AST::Node]
        # @sg-ignore Need to add nil check here
        def data_node
          # @sg-ignore Need to add nil check here
          if node.children[2].type == :block
            # @sg-ignore Need to add nil check here
            node.children[2].children[0]
          else
            node.children[2]
          end
        end
      end
    end
  end
end
