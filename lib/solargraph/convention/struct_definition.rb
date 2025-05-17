# frozen_string_literal: true

module Solargraph
  module Convention
    class StructDefinition < Base
      class StructDefintionNode
        include Parser::ParserGem::NodeMethods

        # @example
        #   s(:class,
        #     s(:const, nil, :Foo),
        #     s(:send,
        #       s(:const, nil, :Struct), :new,
        #       s(:sym, :bar),
        #       s(:sym, :baz)),
        #     s(:def, :foo,
        #       s(:args),
        #       s(:send, nil, :bar)))
        class << self
          def valid?(node)
            return false unless node&.type == :send
            return false unless node.children[0]&.type == :const
            return false unless node.children[0].children[1] == :Struct
            return false unless node.children[1] == :new

            true
          end
        end

        # @return [Parser::AST::Node]
        def initialize(node)
          @node = node
        end

        # @return [String]
        def class_name
          unpack_name(node)
        end

        # @return [Array<Array(Parser::AST::Node, String)>]
        def attributes
          struct_node.children[2..-1].map do |child|
            [child, child.children[0].to_s]
          end
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
      end

      module NodeProcessors
        class StructNode < Parser::NodeProcessor::Base
          # s(:class,
          #   s(:const, nil, :Foo),
          #   s(:send,
          #     s(:const, nil, :Struct), :new,
          #     s(:sym, :bar),
          #     s(:sym, :baz)),
          #   s(:def, :foo,
          #     s(:args),
          #     s(:send, nil, :bar)))
          def process
            return unless StructDefintionNode.valid?(node.children[1])

            struct_def_node = StructDefintionNode.new(node)
            loc = get_node_location(node)
            nspin = Solargraph::Pin::Namespace.new(
              type: node.type,
              location: loc,
              closure: region.closure,
              name: struct_def_node.class_name,
              comments: comments_for(node),
              visibility: :public,
              gates: region.closure.gates.freeze
            )
            pins.push nspin

            struct_def_node.class_name
            # define initialize method
            initialize_method_pin = Pin::Method.new(
              name: 'initialize',
              parameters: [],
              scope: :instance,
              location: get_node_location(node),
              closure: nspin,
              visibility: :private,
              comments: comments_for(node)
            )

            pins.push initialize_method_pin

            struct_def_node.attributes.map do |attribute_node, attribute_name|
              initialize_method_pin.parameters.push(
                Pin::Parameter.new(
                  name: attribute_name,
                  location: get_node_location(attribute_node),
                  closure: initialize_method_pin
                )
              )
            end

            # define attribute accessors
            struct_def_node.attributes.each do |attribute_node, attribute_name|
              [attribute_name, "#{attribute_name}="].each do |name|
                pins.push Pin::Method.new(
                  name: name,
                  parameters: [],
                  scope: :instance,
                  location: get_node_location(attribute_node),
                  closure: nspin,
                  comments: comments_for(node).split("\n").find do |row|
                    row.include?(attribute_name)
                  end&.gsub('@param', '@return')&.gsub(attribute_name, ''),
                  visibility: :public
                )
              end
            end

            process_children region.update(closure: nspin, visibility: :public)
          end
        end
      end
    end
  end
end
