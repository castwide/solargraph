# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class AndNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            process_children

            position = get_node_start_position(node)
            enclosing_breakable_pin = pins.select do |pin|
              pin.is_a?(Pin::Breakable) && pin.location.range.contain?(position)
            end.last
            FlowSensitiveTyping.new(locals, enclosing_breakable_pin).process_and(node)
          end
        end
      end
    end
  end
end
