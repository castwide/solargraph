# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class UntilNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            location = get_node_location(node)
            # Note - this should not be considered a block, as the
            # until statement doesn't create a closure - e.g.,
            # variables created inside can be seen from outside as
            # well
            until_pin = Solargraph::Pin::Until.new(
              location: location,
              closure: region.closure,
              compound_statement: region.compound_statement,
              node: node,
              comments: comments_for(node),
              source: :parser
            )
            pins.push until_pin
            process_children region.update(compound_statement: until_pin, conditional: true)
          end
        end
      end
    end
  end
end
