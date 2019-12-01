# frozen_string_literal: true

module Solargraph
  module Parser
    module Rubyvm
      module NodeProcessors
        class ResbodyNode < Parser::NodeProcessor::Base
          include Rubyvm::NodeMethods

          def process
            presence = Range.from_node(node)
            loc = get_node_location(node.children[1])
            if node.children[1] && node.children[1].children.first
              types = if !node.children.first || node.children.first.children.empty?
                        ['Exception']
                      else
                        node.children.first.children[0..-2].map do |child|
                          unpack_name(child)
                        end
                      end
              locals.push Solargraph::Pin::LocalVariable.new(
                location: loc,
                closure: region.closure,
                name: node.children[1].children.first.children.first.to_s,
                comments: "@type [#{types.join(',')}]",
                presence: presence
              )
            end
            NodeProcessor.process(node.children[1], region, pins, locals)
          end
        end
      end
    end
  end
end
