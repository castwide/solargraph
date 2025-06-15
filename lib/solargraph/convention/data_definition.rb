# frozen_string_literal: true

module Solargraph
  module Convention
    module DataDefinition
      autoload :DataDefintionNode, 'solargraph/convention/data_definition/data_definition_node'
      autoload :DataAssignmentNode, 'solargraph/convention/data_definition/data_assignment_node'

      module NodeProcessors
        class DataNode < Parser::NodeProcessor::Base
          # @return [Boolean] continue processing the next processor of the same node.
          def process
            return true if data_definition_node.nil?

            loc = get_node_location(node)
            nspin = Solargraph::Pin::Namespace.new(
              type: :class,
              location: loc,
              closure: region.closure,
              name: data_definition_node.class_name,
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

            # TODO: Support both arg and kwarg initializers for Data.define
            # Solargraph::SourceMap::Clip#complete_keyword_parameters does not seem to currently take into account [Pin::Method#signatures] hence we only one for :kwarg
            pins.push initialize_method_pin

            data_definition_node.attributes.map do |attribute_node, attribute_name|
              initialize_method_pin.parameters.push(
                Pin::Parameter.new(
                  name: attribute_name,
                  decl: :kwarg,
                  location: get_node_location(attribute_node),
                  closure: initialize_method_pin
                )
              )
            end

            # define attribute readers and instance variables
            data_definition_node.attributes.each do |attribute_node, attribute_name|
              name = attribute_name.to_s
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

              pins.push Pin::InstanceVariable.new(name: "@#{attribute_name}",
                                                  closure: method_pin,
                                                  location: get_node_location(attribute_node),
                                                  comments: attribute_comments(attribute_node, attribute_name))
            end

            process_children region.update(closure: nspin, visibility: :public)

            false
          end

          private

          # @return [DataDefintionNode, nil]
          def data_definition_node
            @data_definition_node ||= if DataDefintionNode.match?(node)
                                        DataDefintionNode.new(node)
                                      elsif DataAssignmentNode.match?(node)
                                        DataAssignmentNode.new(node)
                                      end
          end

          # @param attribute_node [Parser::AST::Node]
          # @return [String, nil]
          def attribute_comments(attribute_node, attribute_name)
            data_comments = comments_for(attribute_node)
            return if data_comments.nil? || data_comments.empty?

            data_comments.split("\n").find do |row|
              row.include?(attribute_name)
            end&.gsub('@param', '@return')&.gsub(attribute_name, '')
          end
        end
      end
    end
  end
end
