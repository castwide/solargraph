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
          def match?(node)
            return false unless node&.type == :class

            data_definition_node?(node.children[1])
          end

          private

          # @param data_node [Parser::AST::Node]
          # @return [Boolean]
          def data_definition_node?(data_node)
            return false unless data_node.is_a?(::Parser::AST::Node)
            return false unless data_node&.type == :send
            return false unless data_node.children[0]&.type == :const
            return false unless data_node.children[0].children[1] == :Data
            return false unless data_node.children[1] == :define

            true
          end
        end

        # @return [Parser::AST::Node]
        def initialize(node)
          @node = node
        end

        # @return [String]
        def class_name
          Parser::NodeMethods.unpack_name(node)
        end

        # @return [Array<Array(Parser::AST::Node, String)>]
        def attributes
          data_attribute_nodes.map do |data_def_param|
            next unless data_def_param.type == :sym
            [data_def_param, data_def_param.children[0].to_s]
          end.compact
        end

        # @return [Parser::AST::Node]
        def body_node
          node.children[2]
        end

        private

        # @return [Parser::AST::Node]
        attr_reader :node

        # @return [Parser::AST::Node]
        def data_node
          node.children[1]
        end

        # @return [Array<Parser::AST::Node>]
        def data_attribute_nodes
          data_node.children[2..-1]
        end
      end
    end
  end
end
