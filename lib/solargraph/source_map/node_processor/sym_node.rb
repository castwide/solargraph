module Solargraph
  class SourceMap
    module NodeProcessor
      class SymNode < Base
        def process
          return # @todo Temporarily disabled
          pins.push Solargraph::Pin::Symbol.new(get_node_location(node), ":#{node.children[0]}")
        end
      end
    end
  end
end
