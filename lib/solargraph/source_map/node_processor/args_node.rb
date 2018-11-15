module Solargraph
  class SourceMap
    module NodeProcessor
      class ArgsNode < Base
        def process
          return if node.children.empty?
          here = get_node_start_position(node)
          context = named_path_pin(here)
          block = block_pin(here)
          if block.kind == Solargraph::Pin::BLOCK
            pi = 0
            node.children.each do |u|
              pins.push Solargraph::Pin::BlockParameter.new(get_node_location(u), region.namespace, "#{u.children[0]}", comments_for(node), block)
              block.parameters.push pins.last
              pi += 1
            end
          else
            node.children.each do |u|
              presence = Range.new(here, block.location.range.ending)
              pins.push Solargraph::Pin::MethodParameter.new(get_node_location(u), region.namespace, u.children[0].to_s, comments_for(node), u.children[1], infer_literal_node_type(u.children[1]), context, block, presence)
            end
          end
        end
      end
    end
  end
end
