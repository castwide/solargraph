# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class CasgnNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            pins.push Solargraph::Pin::Constant.new(
              location: get_node_location(node),
              closure: region.closure,
              name: const_name,
              comments: comments_for(node),
              assignment: node.children[2],
              source: :parser
            )
            process_children
          end

          private

          # @return [String]
          def const_name
            namespace_node = node.children[0]
            if namespace_node
              Parser::NodeMethods.unpack_name(namespace_node) + "::#{node.children[1]}"
            else
              node.children[1].to_s
            end
          end
        end
      end
    end
  end
end
