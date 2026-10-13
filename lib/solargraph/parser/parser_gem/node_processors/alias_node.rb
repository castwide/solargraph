# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class AliasNode < Parser::NodeProcessor::Base
          on_node_pattern_enter '(alias (_ $_) (_ $_))', :process

          # @param name [Symbol]
          # @param original [Symbol]
          # @return [void]
          def process name, original
            loc = get_node_location(node)
            pins.push Solargraph::Pin::MethodAlias.new(
              location: loc,
              closure: region.closure,
              name: name.to_s,
              original: original.to_s,
              scope: region.scope || :instance,
              source: :parser
            )
          end
        end
      end
    end
  end
end
