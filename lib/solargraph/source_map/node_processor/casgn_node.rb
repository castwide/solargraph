module Solargraph
  class SourceMap
    module NodeProcessor
      class CasgnNode < Base
        def process
          here = get_node_start_position(node)
          pins.push Solargraph::Pin::Constant.new(
            location: get_node_location(node),
            closure: region.closure,
            name: node.children[1].to_s,
            comments: comments_for(node),
            assignment: node.children[2]
          )
          process_children
        end
      end
    end
  end
end
