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
            # @sg-ignore
            # @type [Solargraph::Pin::Breakable, nil]
            enclosing_breakable_pin = pins.select{|pin| pin.is_a?(Pin::Breakable) && pin.location.range.contain?(position)}.last
            # @sg-ignore downcast output of Enumerable#select
            # @type [Pin::CompoundStatementable]
            enclosing_compound_statement_pin = pins.select{|pin| pin.is_a?(Solargraph::Pin::CompoundStatementable) && pin.location.range.contain?(position)}.last
            FlowSensitiveTyping.new(locals,
                                    enclosing_breakable_pin,
                                    enclosing_compound_statement_pin).process_and(node)
          end
        end
      end
    end
  end
end
