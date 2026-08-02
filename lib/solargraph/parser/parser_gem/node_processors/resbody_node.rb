# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class ResbodyNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          # @return [void]
          def process
            exception_local = node.children[1] # Exception local variable name
            if exception_local
              here = get_node_start_position(exception_local)
              # @sg-ignore Need to add nil check here
              presence = Range.new(here, region.closure.location.range.ending)
              loc = get_node_location(exception_local)
              exception_classes_node = node.children[0]
              types = if exception_classes_node.nil?
                        ['Exception']
                      else
                        exception_classes_node.children.map do |child|
                          unpack_name(child)
                        end
                      end
              locals.push Solargraph::Pin::LocalVariable.new(
                location: loc,
                closure: region.closure,
                name: exception_local.children[0].to_s,
                comments: "@type [#{types.join(',')}]",
                presence: presence,
                source: :parser
              )
            end
            # @sg-ignore Need to add nil check here
            NodeProcessor.process(node.children[2], region, pins, locals, ivars)
          end
        end
      end
    end
  end
end
