module Solargraph
  class SourceMap
    module NodeProcessor
      class IvasgnNode < Base
        def process
          # here = get_node_start_position(node)
          # named_path = named_path_pin(here)
          # pins.push Solargraph::Pin::InstanceVariable.new(get_node_location(node), region.namespace,node.children[0].to_s, comments_for(node), node.children[1], infer_literal_node_type(node.children[1]), named_path.context)
          # if region.visibility == :module_function and named_path.kind == Pin::METHOD
          #   other = ComplexType.parse("Module<#{named_path.context.namespace}>")
          #   pins.push Solargraph::Pin::InstanceVariable.new(get_node_location(node), region.namespace,node.children[0].to_s, comments_for(node), node.children[1], infer_literal_node_type(node.children[1]), other)
          # end
          loc = get_node_location(node)
          pins.push Solargraph::Pin::InstanceVariable.new(
            location: loc,
            closure: closure_pin(loc.range.start),
            name: node.children[0].to_s,
            comments: comments_for(node),
            assignment: node.children[1],
            scope: region.visibility == :module_function ? :class : region.scope
          )
          if region.visibility == :module_function
            here = get_node_start_position(node)
            named_path = named_path_pin(here)
            if named_path.kind == Pin::METHOD
              pins.push Solargraph::Pin::InstanceVariable.new(
                location: loc,
                closure: closure_pin(loc.range.start),
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
