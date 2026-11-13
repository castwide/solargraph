# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class GvasgnNode < Parser::NodeProcessor::Base
          def process
            loc = get_node_location(node)
            # @sg-ignore https://github.com/castwide/solargraph/pull/1418
            #   also needs https://github.com/castwide/solargraph/pull/1416
            pins.push Solargraph::Pin::GlobalVariable.new(
              location: loc,
              closure: region.closure,
              name: node.children[0].to_s,
              comments: comments_for(node),
              type_assertion: type_assertion_for(node),
              assignment: node.children[1],
              source: :parser
            )
            process_children
          end
        end
      end
    end
  end
end
