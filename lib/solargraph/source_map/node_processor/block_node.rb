module Solargraph
  class SourceMap
    module NodeProcessor
      class BlockNode < Base
        def process
          here = get_node_start_position(node)
          named_path = named_path_pin(here)
          pins.push Solargraph::Pin::Block.new(get_node_location(node), region.namespace, '', comments_for(node), node.children[0], named_path.context)
          process_children
        end
      end
    end
  end
end
