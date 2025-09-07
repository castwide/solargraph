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

            loc = get_node_location(node)
            name = unpack_name(node.children[0])
            nspin = Solargraph::Pin::Namespace.new(
              type: node.type,
              location: loc,
              closure: region.closure,
              name: name,
              comments: comments_for(node),
              visibility: :public,
              gates: region.closure.gates.freeze,
              source: :parser
            )
            logger.debug do
              "NamespaceNode#process: Created namespace pin: #{nspin} in closure #{region.closure} " \
                "and namespace=#{nspin.namespace} and name=#{name}"
            end
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
        end
      end
    end
  end
end
