module Solargraph
  class SourceMap
    module NodeProcessor
      class OrasgnNode < Base
        def process
          new_node = node.updated(node.children[0].type, [node.children[0].children[0], node.children[1]])
          NodeProcessor.process(new_node, region, pins, stack)
        end
      end
    end
  end
end
