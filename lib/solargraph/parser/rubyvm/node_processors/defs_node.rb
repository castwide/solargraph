# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        class DefsNode < DefNode
          include NodeMethods

          def process
            s_visi = region.visibility
            s_visi = :public if region.scope != :class
            loc = get_node_location(node)
            if node.children[0].is_a?(RubyVM::AbstractSyntaxTree::Node) && node.children[0].type == :SELF
              closure = region.closure
            else
              closure = Solargraph::Pin::Namespace.new(
                name: unpack_name(node.children[0])
              )
            end
            if s_visi == :module_function
              pins.push Solargraph::Pin::Method.new(
                location: loc,
                closure: closure,
                name: node.children[1].to_s,
                comments: comments_for(node),
                scope: :class,
                visibility: :public,
                node: node
              )
              pins.push Solargraph::Pin::Method.new(
                location: loc,
                closure: closure,
                name: node.children[1].to_s,
                comments: comments_for(node),
                scope: :instance,
                visibility: :private,
                node: node
              )
            else
              pins.push Solargraph::Pin::Method.new(
                location: loc,
                closure: closure,
                name: node.children[1].to_s,
                comments: comments_for(node),
                scope: :class,
                visibility: s_visi,
                node: node
              )
            end
            process_children region.update(closure: pins.last, scope: :class)
          end
        end
      end
    end
  end
end
