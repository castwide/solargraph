# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class DefsNode < DefNode
          include ParserGem::NodeMethods

          def process
            s_visi = region.visibility
            s_visi = :public if s_visi == :module_function || region.scope != :class
            loc = get_node_location(node)
            closure = if node.children[0].is_a?(AST::Node) && node.children[0].type == :self
                        region.closure
                      else
                        Solargraph::Pin::Namespace.new(
                          name: unpack_name(node.children[0])
                        )
                      end
            pins.push Solargraph::Pin::Method.new(
              location: loc,
              closure: closure,
              name: node.children[1].to_s,
              comments: comments_for(node),
              scope: :class,
              visibility: s_visi,
              node: node,
              source: :parser
            )
            process_children region.update(closure: pins.last, scope: :class)
          end
        end
      end
    end
  end
end
