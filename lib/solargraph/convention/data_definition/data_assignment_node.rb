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
            # s(:casgn, scope, name, value) - value is the call, or a block on it
            return false unless node in [:casgn, _, _, ::Parser::AST::Node => value, *]

            data_node = (value in [:block, ::Parser::AST::Node => call, *]) ? call : value # rubocop:disable Style/RedundantParentheses

            data_definition_node?(data_node)
          end
        end

        def class_name
          # s(:casgn, scope, name, value) - scope is nil for a bare name
          node => [_, ::Parser::AST::Node | nil => scope, Symbol => name, *]

          if scope
            Parser::NodeMethods.unpack_name(scope) + "::#{name}"
          else
            # @sg-ignore https://github.com/castwide/solargraph/pull/1416
            name.to_s
          end
        end

        private

        # @return [Parser::AST::Node]
        # @sg-ignore https://github.com/castwide/solargraph/pull/1416
        def data_node
          node => [_, _, _, ::Parser::AST::Node => value, *]
          (value in [:block, ::Parser::AST::Node => call, *]) ? call : value # rubocop:disable Style/RedundantParentheses
        end
      end
    end
  end
end
