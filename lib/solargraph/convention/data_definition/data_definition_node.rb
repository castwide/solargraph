# frozen_string_literal: true

module Solargraph
  module Convention
    module DataDefinition
      # A node wrapper for a Data definition via inheritance.
      # @example
      #   class MyData < Data.new(:bar, :baz)
      #     def foo
      #     end
      #   end
      class DataDefintionNode
        class << self
          # @example
          #   s(:class,
          #     s(:const, nil, :Foo),
          #     s(:send,
          #       s(:const, nil, :Data), :define,
          #       s(:sym, :bar),
          #       s(:sym, :baz)),
          #       s(:hash,
          #         s(:pair,
          #           s(:sym, :keyword_init),
          #           s(:true)))),
          #     s(:def, :foo,
          #       s(:args),
          #       s(:send, nil, :bar)))
          #
          # @param node [Parser::AST::Node]
          def match? node
            return false unless node in [:class, _, ::Parser::AST::Node | nil => superclass, *]

            # @sg-ignore https://github.com/castwide/solargraph/pull/1416
            data_definition_node?(superclass)
          end

          private

          # @param data_node [Parser::AST::Node, nil]
          # @return [Boolean]
          # @sg-ignore https://github.com/castwide/solargraph/pull/1416
          def data_definition_node? data_node
            # Data.define(*args) - s(:send, s(:const, scope, :Data), :define, *args)
            data_node in ::Parser::AST::Node[:send, [:const, _, :Data, *], :define, *]
          end
        end

        # @param node [Parser::AST::Node]
        def initialize node
          @node = node
        end

        # @return [String]
        def class_name
          Parser::NodeMethods.unpack_name(node)
        end

        # @return [Array<Array(Parser::AST::Node, String)>]
        def attributes
          data_attribute_nodes.map do |data_def_param|
            next unless data_def_param in [:sym, Symbol => name]

            # @sg-ignore https://github.com/castwide/solargraph/pull/1416
            [data_def_param, name.to_s]
          end.compact
        end

        # @return [Parser::AST::Node, nil]
        def body_node
          # s(:class, name, superclass, body)
          (node in [_, _, _, ::Parser::AST::Node | nil => body, *]) ? body : nil # rubocop:disable Style/RedundantParentheses
        end

        private

        # @return [Parser::AST::Node]
        attr_reader :node

        # @return [Parser::AST::Node, nil]
        def data_node
          (node in [_, _, ::Parser::AST::Node | nil => superclass, *]) ? superclass : nil # rubocop:disable Style/RedundantParentheses
        end

        # @sg-ignore Need to add nil check here
        # @return [Array<Parser::AST::Node>]
        def data_attribute_nodes
          data_node => [_, _, _, *args]
          args
        end
      end
    end
  end
end
