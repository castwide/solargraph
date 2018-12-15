module Solargraph
  class SourceMap
    module NodeProcessor
      class DefsNode < DefNode
        def process
          s_visi = region.visibility
          s_visi = :public if s_visi == :module_function || region.scope != :class
          if node.children[0].is_a?(AST::Node) && node.children[0].type == :self
            dfqn = region.namespace
          else
            dfqn = unpack_name(node.children[0])
          end
          unless dfqn.nil?
            pins.push Solargraph::Pin::Method.new(get_node_location(node), dfqn, "#{node.children[1]}", comments_for(node), :class, s_visi, method_args, node)
            process_children region.update(namespace: dfqn)
          end
        end
      end
    end
  end
end
