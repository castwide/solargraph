# frozen_string_literal: true

module Solargraph
  module Convention
    module StructDefinition
      autoload :StructDefintionNode, 'solargraph/convention/struct_definition/struct_definition_node'
      autoload :StructAssignmentNode, 'solargraph/convention/struct_definition/struct_assignment_node'

      module NodeProcessors
        class StructNode < Parser::NodeProcessor::Base
          # @return [Boolean] continue processing the next processor of the same node.
          def process
            return true if struct_definition_node.nil?

            loc = get_node_location(node)
            nspin = Solargraph::Pin::Namespace.new(
              type: :class,
              location: loc,
              closure: region.closure,
              name: struct_definition_node.class_name,
              docstring: docstring,
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
              docstring: docstring
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
                docs = docstring.tags.find { |t| t.tag_name == 'param' && t.name == attribute_name }

                method_pin = Pin::Method.new(
                  name: name,
                  parameters: [],
                  scope: :instance,
                  location: get_node_location(attribute_node),
                  closure: nspin,
                  # even assignments return the value
                  comments: attribute_comment(docs, false),
                  visibility: :public
                )

                if name.end_with?('=')
                  method_pin.parameters << Pin::Parameter.new(
                    name: attribute_name,
                    location: get_node_location(attribute_node),
                    closure: nspin,
                    comments: attribute_comment(docs, true)
                  )

                  pins.push Pin::InstanceVariable.new(name: "@#{attribute_name}",
                                    closure: method_pin,
                                    location: get_node_location(attribute_node),
                                    comments: attribute_comment(docs, false))
                end

                pins.push method_pin
              end
            end

            process_children region.update(closure: nspin, visibility: :public)
            false
          end

          private

          # @return [StructDefintionNode, nil]
          def struct_definition_node
            @struct_definition_node ||= if StructDefintionNode.match?(node)
                                          StructDefintionNode.new(node)
                                        elsif StructAssignmentNode.match?(node)
                                          StructAssignmentNode.new(node)
                                        end
          end

          # Gets/generates the relevant docstring for this struct & it's attributes
          # @return [YARD::Docstring]
          def docstring
            @docstring ||= parse_comments
          end

          # Parses any relevant comments for a struct int a yard docstring
          # @return [YARD::Docstring]
          def parse_comments
            struct_comments = comments_for(node) || ''
            struct_definition_node.attributes.each do |attr_node, attr_name|
              comment = comments_for(attr_node)
              next if comment.nil?

              # We should support specific comments for an attribute, and that can be either a @return on an @param
              # But since we merge into the struct_comments, then we should interpret either as a param
              comment = '@param ' + attr_name + comment[7..] if comment.start_with?('@return')

              struct_comments += "\n#{comment}"
            end

            Solargraph::Source.parse_docstring(struct_comments).to_docstring
          end

          # @param tag [YARD::Tags::Tag, nil] The param tag for this attribute. If nil, this method is a no-op
          # @param for_setter [Boolean] If true, will return a @param tag instead of a @return tag
          def attribute_comment(tag, for_setter)
            return "" if tag.nil?

            suffix = "[#{tag.types&.join(',') || 'undefined'}] #{tag.text}"

            if for_setter
              "@param #{tag.name} #{suffix}"
            else
              "@return #{suffix}"
            end
          end
        end
      end
    end
  end
end
