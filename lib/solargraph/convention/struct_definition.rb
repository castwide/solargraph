# frozen_string_literal: true

module Solargraph
  module Convention
    class StructDefinition < Base
      class StructDefintionNode
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
        class << self
          def valid?(node)
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

      class StructAssignmentNode < StructDefintionNode
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
        class << self
          def valid?(node)
            return false unless node&.type == :casgn
            return false if node.children[2].nil?
            struct_node = node.children[2].children[0]

            struct_definition_node?(struct_node)
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
        # @return [Parser::AST::Node]
        def struct_node
          node.children[2].children[0]
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
            return if struct_def_node.nil?

            loc = get_node_location(node)
            nspin = Solargraph::Pin::Namespace.new(
              type: :class,
              location: loc,
              closure: region.closure,
              name: struct_def_node.class_name,
              comments: comments_for(node),
              visibility: :public,
              gates: region.closure.gates.freeze
            )
            pins.push nspin

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
                  decl: struct_def_node.keyword_init? ? :kwarg : :arg,
                  location: get_node_location(attribute_node),
                  closure: initialize_method_pin
                )
              )
            end

            # define attribute accessors and instance variables
            struct_def_node.attributes.each do |attribute_node, attribute_name|
              [attribute_name, "#{attribute_name}="].each do |name|
                method_pin = Pin::Method.new(
                  name: name,
                  parameters: [],
                  scope: :instance,
                  location: get_node_location(attribute_node),
                  closure: nspin,
                  comments: attribute_comments(attribute_node, attribute_name),
                  visibility: :public
                )

                pins.push method_pin

                if name.include?('=') # setter
                  pins.push Pin::InstanceVariable.new(name: "@#{attribute_name}",
                                                      closure: method_pin,
                                                      location: get_node_location(attribute_node),
                                                      comments: attribute_comments(attribute_node, attribute_name))
                end
              end

            end

            process_children region.update(closure: nspin, visibility: :public)
          end

          private

          # @return [StructDefintionNode, nil]
          def struct_def_node
            @struct_def_node ||= if StructDefintionNode.valid?(node)
                                   StructDefintionNode.new(node)
                                 elsif StructAssignmentNode.valid?(node)
                                   StructAssignmentNode.new(node)
                                 end
          end

          # @param attribute_node [Parser::AST::Node]
          # @return [String, nil]
          def attribute_comments(attribute_node, attribute_name)
            comments_for(attribute_node).split("\n").find do |row|
              row.include?(attribute_name)
            end&.gsub('@param', '@return')&.gsub(attribute_name, '')
          end
        end
      end
    end
  end
end
