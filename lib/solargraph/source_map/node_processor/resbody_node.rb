module Solargraph
  class SourceMap
    module NodeProcessor
      class ResbodyNode < Base
        def process
          if node.children[1]
            here = get_node_start_position(node.children[1])
            presence = Range.new(here, region.closure.location.range.ending)
            loc = get_node_location(node.children[1])
            types = if node.children[0].nil?
                      ['Exception']
                    else
                      node.children[0].children.map do |child|
                        unpack_name(child)
                      end
                    end
            pins.push Solargraph::Pin::LocalVariable.new(
              location: loc,
              closure: region.closure,
              name: node.children[1].children[0].to_s,
              comments: "@type [#{types.join(',')}]",
              presence: presence
            )
          end
          NodeProcessor.process(node.children[2], region, pins)
        end
      end
    end
  end
end
