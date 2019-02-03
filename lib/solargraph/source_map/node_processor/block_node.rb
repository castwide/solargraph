module Solargraph
  class SourceMap
    module NodeProcessor
      class BlockNode < Base
        def process
          here = get_node_start_position(node)
          pins.push Solargraph::Pin::Block.new(
            location: get_node_location(node),
            closure: closure_pin(here),
            receiver: node.children[0],
            comments: comments_for(node),
            scope: region.scope || closure_pin(here).context.scope
          )
          process_children
        end
      end
    end
  end
end
