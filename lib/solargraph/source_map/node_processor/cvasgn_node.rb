module Solargraph
  class SourceMap
    module NodeProcessor
      class CvasgnNode < Base
        def process
          here = get_node_start_position(node)
          context = named_path_pin(here)
          pins.push Solargraph::Pin::ClassVariable.new(get_node_location(node), region.namespace, node.children[0].to_s, comments_for(node), node.children[1], infer_literal_node_type(node.children[1]), context.context)
        end
      end
    end
  end
end
