# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class CasgnNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            if Convention::StructDefinition::StructAssignmentNode.valid?(node)
              process_struct_assignment
            else
              process_constant_assignment
            end
          end

          private

          # @return [void]
          def process_constant_assignment
            pins.push Solargraph::Pin::Constant.new(
              location: get_node_location(node),
              closure: region.closure,
              name: const_name,
              comments: comments_for(node),
              assignment: node.children[2],
              source: :parser
            )
            process_children
          end

          # @todo Move this out of [CasgnNode] once [Solargraph::Parser::NodeProcessor] supports
          #   multiple processors.
          def process_struct_assignment
            processor_klass = Convention::StructDefinition::NodeProcessors::StructNode
            processor = processor_klass.new(node, region, pins, locals)
            processor.process

            @pins = processor.pins
            @locals = processor.locals
          end

          # @return [String]
          def const_name
            if node.children[0]
              Parser::NodeMethods.unpack_name(node.children[0]) + "::#{node.children[1]}"
            else
              node.children[1].to_s
            end
          end
        end
      end
    end
  end
end
