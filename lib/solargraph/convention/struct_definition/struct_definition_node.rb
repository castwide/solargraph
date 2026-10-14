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
          #
          # @param node [Parser::AST::Node]
          def match? node
            return false unless node in [:class, _, superclass, *]

            struct_definition_node?(superclass)
          end

          private

          # @param struct_node [Parser::AST::Node]
          # @return [Boolean]
          def struct_definition_node? struct_node
            # Struct.new(*args) - s(:send, s(:const, scope, :Struct), :new, *args)
            struct_node in ::Parser::AST::Node[:send, [:const, _, :Struct, *], :new, *]
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
          struct_attribute_nodes.map do |struct_def_param|
            next unless struct_def_param in [:sym, name]

            [struct_def_param, name.to_s]
          end.compact
        end

        def keyword_init?
          # keyword_init: true - s(:hash, s(:pair, s(:sym, :keyword_init), s(:true)), *pairs)
          keyword_init_param = struct_attribute_nodes.find do |struct_def_param|
            struct_def_param in [:hash, [:pair, [_, :keyword_init, *], _], *]
          end

          keyword_init_param in [:hash, [:pair, _, [:true, *]], *]
        end

        # @return [Parser::AST::Node]
        def body_node
          # s(:class, name, superclass, body)
          (node in [_, _, _, body, *]) ? body : nil # rubocop:disable Style/RedundantParentheses
        end

        private

        # @return [Parser::AST::Node]
        attr_reader :node

        # @return [Parser::AST::Node]
        def struct_node
          (node in [_, _, superclass, *]) ? superclass : nil # rubocop:disable Style/RedundantParentheses
        end

        # @sg-ignore Need to add nil check here
        # @return [Array<Parser::AST::Node>]
        def struct_attribute_nodes
          struct_node => [_, _, _, *args]
          args
        end
      end
    end
  end
end
