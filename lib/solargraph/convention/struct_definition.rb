# frozen_string_literal: true

module Solargraph
  module Convention
    module StructDefinition
      autoload :StructDefintionNode, 'solargraph/convention/struct_definition/struct_definition_node'
      autoload :StructAssignmentNode, 'solargraph/convention/struct_definition/struct_assignment_node'

      module NodeProcessors
        class StructNode < Parser::NodeProcessor::Base
          def process
            return if struct_definition_node.nil?

            loc = get_node_location(node)
            nspin = Solargraph::Pin::Namespace.new(
              type: :class,
              location: loc,
              closure: region.closure,
              name: struct_definition_node.class_name,
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

            struct_definition_node.attributes.map do |attribute_node, attribute_name|
              initialize_method_pin.parameters.push(
                Pin::Parameter.new(
                  name: attribute_name,
                  decl: struct_definition_node.keyword_init? ? :kwarg : :arg,
                  location: get_node_location(attribute_node),
                  closure: initialize_method_pin
                )
              )
            end

            # define attribute accessors and instance variables
            struct_definition_node.attributes.each do |attribute_node, attribute_name|
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

                next unless name.include?('=') # setter
                pins.push Pin::InstanceVariable.new(name: "@#{attribute_name}",
                                                    closure: method_pin,
                                                    location: get_node_location(attribute_node),
                                                    comments: attribute_comments(attribute_node, attribute_name))
              end
            end

            process_children region.update(closure: nspin, visibility: :public)
          end

          private

          # @return [StructDefintionNode, nil]
          def struct_definition_node
            @struct_definition_node ||= if StructDefintionNode.valid?(node)
                                          StructDefintionNode.new(node)
                                        elsif StructAssignmentNode.valid?(node)
                                          StructAssignmentNode.new(node)
                                        end
          end

          # @param attribute_node [Parser::AST::Node]
          # @return [String, nil]
          def attribute_comments(attribute_node, attribute_name)
            struct_comments = comments_for(attribute_node)
            return if struct_comments.nil? || struct_comments.empty?

            struct_comments.split("\n").find do |row|
              row.include?(attribute_name)
            end&.gsub('@param', '@return')&.gsub(attribute_name, '')
          end
        end
      end
    end
  end
end
