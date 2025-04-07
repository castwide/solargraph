# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class IfNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            process_children

            position = get_node_start_position(node)
            enclosing_block_pin = pins.select{|pin| pin.is_a?(Pin::Block) && pin.location.range.contain?(position)}.last
            FlowSensitiveTyping.new(locals, enclosing_block_pin).process_if(node)
          end
        end
      end
    end
  end
end
