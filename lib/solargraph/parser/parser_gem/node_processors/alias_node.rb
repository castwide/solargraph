# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class AliasNode < Parser::NodeProcessor::Base
          def process
            # s(:alias, s(:sym, new), s(:sym, old)) - gvar aliases use s(:gvar, name)
            return process_children unless node in [:alias, [_, new_name, *], [_, original, *]]

            loc = get_node_location(node)
            pins.push Solargraph::Pin::MethodAlias.new(
              location: loc,
              closure: region.closure,
              name: new_name.to_s,
              original: original.to_s,
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
