module Solargraph
  class SourceMap
    module NodeProcessor
      class AliasNode < Base
        def process
          loc = get_node_location(node)
          pins.push Solargraph::Pin::MethodAlias.new(
            location: loc,
            closure: closure_pin(loc.range.start),
            name: node.children[0].children[0].to_s,
            original: node.children[1].children[0].to_s,
            scope: region.scope || :instance
          )
          process_children
        end
      end
    end
  end
end
