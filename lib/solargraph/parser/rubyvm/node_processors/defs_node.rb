# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        class DefsNode < DefNode
          def process
            s_visi = region.visibility
            s_visi = :public if s_visi == :module_function || region.scope != :class
            loc = get_node_location(node)
            if node.children[0].is_a?(RubyVM::AbstractSyntaxTree::Node) && node.children[0].type == :SELF
              closure = region.closure
            else
              closure = Solargraph::Pin::Namespace.new(
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
              node: node
            )
            process_children region.update(closure: pins.last, scope: :class)
          end

          # @todo This belongs elsewhere
          def unpack_name node
            pack_name(node).join('::')
          end

          # @todo This belongs elsewhere
          def pack_name(node)
            parts = []
            if node.is_a?(RubyVM::AbstractSyntaxTree::Node)
              node.children.each { |n|
                if n.is_a?(RubyVM::AbstractSyntaxTree::Node)
                  if n.type == :COLON2
                    parts = [''] + pack_name(n)
                  else
                    parts += pack_name(n)
                  end
                else
                  parts.push n unless n.nil?
                end
              }
            end
            parts
          end
        end
      end
    end
  end
end
