module Solargraph
  class SourceMap
    module NodeProcessor
      class BlockNode < Base
        def process
          here = get_node_start_position(node)
          named_path = named_path_pin(here)
          # pins.push Solargraph::Pin::Block.new(get_node_location(node), region.namespace, '', comments_for(node), node.children[0], named_path.context)
          pins.push Solargraph::Pin::Block.new(
            location: get_node_location(node),
            closure: closure_pin(here),
            receiver: node.children[0],
            comments: comments_for(node)
          )
          process_children
        end
      end
    end
  end
end
