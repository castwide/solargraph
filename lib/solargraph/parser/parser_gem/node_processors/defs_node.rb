# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class DefsNode < DefNode
          include ParserGem::NodeMethods

          on_node_pattern_enter '(defs $_ $_ ...)', :process

          # @param receiver [::Parser::AST::Node]
          # @param name [Symbol]
          # @return [void]
          def process receiver, name
            s_visi = region.visibility
            s_visi = :public if s_visi == :module_function || region.scope != :class
            loc = get_node_location(node)
            closure = if receiver.type == :self
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
              name: name.to_s,
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
