module Solargraph
  class SourceMap
    module NodeProcessor
      class CasgnNode < Base
        def process
          here = get_node_start_position(node)
          block = block_pin(here)
          pins.push Solargraph::Pin::Constant.new(get_node_location(node), region.namespace, node.children[1].to_s, comments_for(node), node.children[2], infer_literal_node_type(node.children[2]), block.context, :public)
        end
      end
    end
  end
end
