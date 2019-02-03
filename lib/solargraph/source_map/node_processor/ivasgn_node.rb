module Solargraph
  class SourceMap
    module NodeProcessor
      class IvasgnNode < Base
        def process
          loc = get_node_location(node)
          clos = closure_pin(loc.range.start)
          pins.push Solargraph::Pin::InstanceVariable.new(
            location: loc,
            closure: clos,
            name: node.children[0].to_s,
            comments: comments_for(node),
            assignment: node.children[1],
            scope: region.visibility == :module_function ? :class : (region.scope || closure_pin(loc.range.start).scope)
          )
          if region.visibility == :module_function
            here = get_node_start_position(node)
            named_path = named_path_pin(here)
            if named_path.kind == Pin::METHOD
              pins.push Solargraph::Pin::InstanceVariable.new(
                location: loc,
                closure: clos,
                name: node.children[0].to_s,
                comments: comments_for(node),
                assignment: node.children[1],
                scope: :instance
              )
            end
          end
          process_children
        end
      end
    end
  end
end
