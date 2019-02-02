module Solargraph
  class SourceMap
    module NodeProcessor
      class LvasgnNode < Base
        def process
          # here = get_node_start_position(node)
          # context = named_path_pin(here)
          # block = block_pin(here)
          # presence = Range.new(here, block.location.range.ending)
          # pins.push Solargraph::Pin::LocalVariable.new(get_node_location(node), region.namespace, node.children[0].to_s, comments_for(node), node.children[1], infer_literal_node_type(node.children[1]), context.context, block, presence)
          loc = get_node_location(node)
          pins.push Solargraph::Pin::LocalVariable.new(
            location: loc,
            closure: closure_pin(loc.range.start),
            name: node.children[0].to_s,
            assignment: node.children[1],
            comments: comments_for(node)
          )
          process_children
        end
      end
    end
  end
end
