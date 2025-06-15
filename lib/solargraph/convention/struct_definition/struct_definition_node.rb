# frozen_string_literal: true

module Solargraph
  module Convention
    module StructDefinition
      # A node wrapper for a Struct definition via inheritance.
      # @example
      #   class MyStruct < Struct.new(:bar, :baz)
      #     def foo
      #     end
      #   end
      class StructDefintionNode
        class << self
          # @example
          #   s(:class,
          #     s(:const, nil, :Foo),
          #     s(:send,
          #       s(:const, nil, :Struct), :new,
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

            struct_definition_node?(node.children[1])
          end

          private

          # @param struct_node [Parser::AST::Node]
          # @return [Boolean]
          def struct_definition_node?(struct_node)
            return false unless struct_node.is_a?(::Parser::AST::Node)
            return false unless struct_node&.type == :send
            return false unless struct_node.children[0]&.type == :const
            return false unless struct_node.children[0].children[1] == :Struct
            return false unless struct_node.children[1] == :new

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
          struct_attribute_nodes.map do |struct_def_param|
            next unless struct_def_param.type == :sym
            [struct_def_param, struct_def_param.children[0].to_s]
          end.compact
        end

        def keyword_init?
          keyword_init_param = struct_attribute_nodes.find do |struct_def_param|
            struct_def_param.type == :hash && struct_def_param.children[0].type == :pair &&
              struct_def_param.children[0].children[0].children[0] == :keyword_init
          end

          return false if keyword_init_param.nil?

          keyword_init_param.children[0].children[1].type == :true
        end

        # @return [Parser::AST::Node]
        def body_node
          node.children[2]
        end

        private

        # @return [Parser::AST::Node]
        attr_reader :node

        # @return [Parser::AST::Node]
        def struct_node
          node.children[1]
        end

        # @return [Array<Parser::AST::Node>]
        def struct_attribute_nodes
          struct_node.children[2..-1]
        end
      end
    end
  end
end
