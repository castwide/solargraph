# frozen_string_literal: true

module Solargraph
  module Convention
    # Handles anonymous class definitions assigned to a constant, e.g.
    #
    #   Specific = Class.new(StandardError) do
    #     def retry_after; 5; end
    #   end
    #
    # Without this, the constant is indexed as an untyped Pin::Constant and the
    # methods in the block are attached to the enclosing namespace.
    module ClassDefinition
      autoload :ClassAssignmentNode, 'solargraph/convention/class_definition/class_assignment_node'

      module NodeProcessors
        class ClassNode < Parser::NodeProcessor::Base
          # @return [Boolean] continue processing the next processor of the same node.
          def process
            definition_node = class_definition_node
            return true if definition_node.nil?

            loc = get_node_location(node)
            nspin = Solargraph::Pin::Namespace.new(
              type: :class,
              location: loc,
              closure: region.closure,
              name: definition_node.class_name,
              comments: comments_for(node),
              visibility: :public,
              gates: region.closure.gates.freeze,
              source: :class_definition
            )
            pins.push nspin

            superclass_name = definition_node.superclass_name
            if superclass_name
              pins.push Pin::Reference::Superclass.new(
                location: loc,
                closure: nspin,
                name: superclass_name,
                source: :class_definition
              )
            end

            process_children region.update(closure: nspin, visibility: :public)
            false
          end

          private

          # @return [ClassDefinition::ClassAssignmentNode, nil]
          def class_definition_node
            @class_definition_node ||= ClassAssignmentNode.new(node) if ClassAssignmentNode.match?(node)
          end
        end
      end
    end
  end
end
