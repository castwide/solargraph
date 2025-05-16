# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class NamespaceNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            sc = nil
            if node.type == :class and node.children[1]&.type == :const
              sc = unpack_name(node.children[1])
            end
            return if Convention::StructDefinition::StructDefintionNode.valid?(node.children[1])
            loc = get_node_location(node)
            nspin = Solargraph::Pin::Namespace.new(
              type: node.type,
              location: loc,
              closure: region.closure,
              name: unpack_name(node.children[0]),
              comments: comments_for(node),
              visibility: :public,
              gates: region.closure.gates.freeze
            )
            pins.push nspin
            unless sc.nil?
              pins.push Pin::Reference::Superclass.new(
                location: loc,
                closure: pins.last,
                name: sc
              )
            end
            process_children region.update(closure: nspin, visibility: :public)
          end
        end
      end
    end
  end
end
