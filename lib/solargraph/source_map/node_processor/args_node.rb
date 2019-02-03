module Solargraph
  class SourceMap
    module NodeProcessor
      class ArgsNode < Base
        def process
          node.children.each do |u|
            loc = get_node_location(u)
            pins.push Solargraph::Pin::Parameter.new(
              location: loc,
              closure: closure_pin(loc.range.start),
              comments: comments_for(node),
              name: u.children[0].to_s,
              assignment: u.children[1],
              presence: closure_pin(loc.range.start).location.range
            )
          end
          process_children
        end
      end
    end
  end
end
