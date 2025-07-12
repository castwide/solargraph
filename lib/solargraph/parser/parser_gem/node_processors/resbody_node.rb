# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class ResbodyNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          # @return [void]
          def process
            if node.children[1] # Exception local variable name
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
              locals.push Solargraph::Pin::LocalVariable.new(
                location: loc,
                closure: region.closure,
                name: node.children[1].children[0].to_s,
                comments: "@type [#{types.join(',')}]",
                presence: presence,
                source: :parser
              )
            end
            NodeProcessor.process(node.children[2], region, pins, locals)
          end
        end
      end
    end
  end
end
