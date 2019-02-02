module Solargraph
  class SourceMap
    module NodeProcessor
      class DefsNode < DefNode
        def process
          s_visi = region.visibility
          s_visi = :public if s_visi == :module_function || region.scope != :class
          loc = get_node_location(node)
          if node.children[0].is_a?(AST::Node) && node.children[0].type == :self
            closure = closure_pin(loc.range.start)
          else
            # dfqn = unpack_name(node.children[0])
            closure = Solargraph::Pin::Namespace.new(
              name: unpack_name(node.children[0])
            )
          end
          # unless dfqn.nil?
          #   pins.push Solargraph::Pin::Method.new(get_node_location(node), dfqn, "#{node.children[1]}", comments_for(node), :class, s_visi, method_args, node)
          #   process_children region.update(namespace: dfqn)
          # end
          pins.push Solargraph::Pin::Method.new(
            location: loc,
            closure: closure,
            name: node.children[1].to_s,
            comments: comments_for(node),
            scope: :class,
            visibility: s_visi,
            args: method_args,
            node: node
          )
          process_children region.update(namespace: closure.context.namespace, scope: :class)
        end
      end
    end
  end
end
