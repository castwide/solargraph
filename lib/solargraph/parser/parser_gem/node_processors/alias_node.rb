# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class AliasNode < Parser::NodeProcessor::Base
          def process
            loc = get_node_location(node)
            pins.push Solargraph::Pin::MethodAlias.new(
              location: loc,
              closure: region.closure,
              # @sg-ignore https://github.com/castwide/solargraph/pull/1391
              name: node.children[0].children[0].to_s,
              # @sg-ignore https://github.com/castwide/solargraph/pull/1391
              original: node.children[1].children[0].to_s,
              scope: region.scope || :instance,
              source: :parser
            )
            process_children
          end
        end
      end
    end
  end
end
