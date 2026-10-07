# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class CasgnNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          on_node_type :casgn, :process

          # @!method node
          #   @return [RuboCop::AST::CasgnNode]

          # @return [void]
          def process
            pins.push Solargraph::Pin::Constant.new(
              location: get_node_location(node),
              closure: region.closure,
              name: const_name,
              comments: comments_for(node),
              assignment: node.expression,
              source: :parser
            )
          end

          private

          # @return [String]
          def const_name
            namespace = node.namespace
            if namespace
              Parser::NodeMethods.unpack_name(namespace) + "::#{node.name}"
            else
              node.name.to_s
            end
          end
        end
      end
    end
  end
end
