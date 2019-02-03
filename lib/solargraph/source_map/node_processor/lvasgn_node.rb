module Solargraph
  class SourceMap
    module NodeProcessor
      class LvasgnNode < Base
        def process
          here = get_node_start_position(node)
          block = block_pin(here)
          presence = Range.new(here, block.location.range.ending)
          loc = get_node_location(node)
          pins.push Solargraph::Pin::LocalVariable.new(
            location: loc,
            closure: closure_pin(loc.range.start),
            name: node.children[0].to_s,
            assignment: node.children[1],
            comments: comments_for(node),
            presence: presence
          )
          process_children
        end
      end
    end
  end
end
