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
            # s(:casgn, scope, name, value) - value is the call, or a block on it
            return false unless node in [:casgn, _, _, ::Parser::AST::Node => value, *]

            struct_node = (value in [:block, ::Parser::AST::Node => call, *]) ? call : value # rubocop:disable Style/RedundantParentheses

            struct_definition_node?(struct_node)
          end
        end

        def class_name
          # s(:casgn, scope, name, value) - scope is nil for a bare name
          node => [_, ::Parser::AST::Node | nil => scope, Symbol => name, *]

          if scope
            Parser::NodeMethods.unpack_name(scope) + "::#{name}"
          else
            name.to_s
          end
        end

        private

        # @return [Parser::AST::Node]
        def struct_node
          node => [_, _, _, ::Parser::AST::Node => value, *]
          (value in [:block, ::Parser::AST::Node => call, *]) ? call : value # rubocop:disable Style/RedundantParentheses
        end
      end
    end
  end
end
