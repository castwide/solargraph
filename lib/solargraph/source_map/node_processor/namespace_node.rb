module Solargraph
  class SourceMap
    module NodeProcessor
      class NamespaceNode < Base
        def process
          visibility = :public
          if node.children[0].kind_of?(AST::Node) and node.children[0].children[0].kind_of?(AST::Node) and node.children[0].children[0].type == :cbase
            tree = pack_name(node.children[0])
            tree.shift if tree.first.empty?
          else
            tree = region.namespace.empty? ? [] : [region.namespace]
            tree.concat pack_name(node.children[0])
          end
          fqn = tree.join('::')
          sc = nil
          if node.type == :class and !node.children[1].nil?
            sc = unpack_name(node.children[1])
          end
          loc = get_node_location(node)
          # pins.push Solargraph::Pin::Namespace.new(get_node_location(node), tree[0..-2].join('::') || '', pack_name(node.children[0]).last.to_s, comments_for(node), node.type, visibility)
          # pins.push Pin::Reference::Superclass.new(pins.last.location, pins.last.path, sc) unless sc.nil?
          pins.push Solargraph::Pin::Namespace.new(
            type: node.type,
            location: loc,
            closure: closure_pin(loc.range.start),
            name: unpack_name(node.children[0]),
            comments: comments_for(node),
            visibility: :public
          )
          pins.push Pin::Reference::Superclass.new(
            location: loc,
            closure: pins.last,
            name: sc
          ) unless sc.nil?
          process_children region.update(namespace: fqn, scope: :instance, visibility: :public)
        end
      end
    end
  end
end
