module Solargraph
  class SourceMap
    module NodeProcessor
      class AliasNode < Base
        def process
          pin = pins.select{|p| p.name == node.children[1].children[0].to_s && p.namespace == region.namespace && p.scope == region.scope}.first
          if pin.nil?
            pins.push Solargraph::Pin::MethodAlias.new(get_node_location(node), region.namespace, node.children[0].children[0].to_s, region.scope, node.children[1].children[0].to_s)
          else
            if pin.is_a?(Solargraph::Pin::Method)
              pins.push Solargraph::Pin::Method.new(get_node_location(node), pin.namespace, node.children[0].children[0].to_s, comments_for(node) || pin.comments, pin.scope, pin.visibility, pin.parameters, pin.node)
            elsif pin.is_a?(Solargraph::Pin::Attribute)
              pins.push Solargraph::Pin::Attribute.new(get_node_location(node), pin.namespace, node.children[0].children[0].to_s, comments_for(node) || pin.comments, pin.access, pin.scope, pin.visibility)
            end
          end
          process_children
        end
      end
    end
  end
end
