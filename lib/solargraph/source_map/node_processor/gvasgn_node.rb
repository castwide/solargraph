module Solargraph
  class SourceMap
    module NodeProcessor
      class GvasgnNode < Base
        def process
          pins.push Solargraph::Pin::GlobalVariable.new(get_node_location(node), region.namespace, node.children[0].to_s, comments_for(node), node.children[1], infer_literal_node_type(node.children[1]), pins.first.context)
        end
      end
    end
  end
end
