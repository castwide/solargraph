module Solargraph
  class SourceMap
    module NodeProcessor
      class SymNode < Base
        def process
          pins.push Solargraph::Pin::Symbol.new(
            get_node_location(node),
            ":#{node.children[0]}"
          )
        end
      end
    end
  end
end
