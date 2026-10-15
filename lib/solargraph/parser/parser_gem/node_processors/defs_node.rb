# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class DefsNode < DefNode
          include ParserGem::NodeMethods

          def process
            # s(:defs, receiver, name, args, body)
            return process_children unless node in [:defs, ::Parser::AST::Node => receiver, Symbol => method_name, *]

            s_visi = region.visibility
            s_visi = :public if s_visi == :module_function || region.scope != :class
            loc = get_node_location(node)
            closure = if receiver in ::AST::Node[:self, *]
                        region.closure
                      else
                        Solargraph::Pin::Namespace.new(
                          name: unpack_name(receiver),
                          source: :parser
                        )
                      end
            pins.push Solargraph::Pin::Method.new(
              location: loc,
              closure: closure,
              name: method_name.to_s,
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
