# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class NamespaceNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            superclass_name = nil
            superclass_name = unpack_name(node.children[1]) if node.type == :class && node.children[1]&.type == :const

            if Convention::StructDefinition::StructDefintionNode.valid?(node)
              process_struct_definition
            else
              process_namespace(superclass_name)
            end
          end

          private

          # @param superclass_name [String, nil]
          def process_namespace(superclass_name)
            loc = get_node_location(node)
            nspin = Solargraph::Pin::Namespace.new(
              type: node.type,
              location: loc,
              closure: region.closure,
              name: unpack_name(node.children[0]),
              comments: comments_for(node),
              visibility: :public,
              gates: region.closure.gates.freeze,
              source: :parser
            )
            pins.push nspin
            unless superclass_name.nil?
              pins.push Pin::Reference::Superclass.new(
                location: loc,
                closure: pins.last,
                name: superclass_name,
                source: :parser
              )
            end
            process_children region.update(closure: nspin, visibility: :public)
          end

          # @todo Move this out of [NamespaceNode] once [Solargraph::Parser::NodeProcessor] supports
          #   multiple processors.
          def process_struct_definition
            processor_klass = Convention::StructDefinition::NodeProcessors::StructNode
            processor = processor_klass.new(node, region, pins, locals)
            processor.process

            @pins = processor.pins
            @locals = processor.locals
          end
        end
      end
    end
  end
end
