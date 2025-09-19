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
            # @sg-ignore
            # @type [Solargraph::Pin::Breakable, nil]
            enclosing_breakable_pin = pins.select{|pin| pin.is_a?(Pin::Breakable) && pin.location.range.contain?(position)}.last
            # @sg-ignore downcast output of Enumerable#select
            # @type [Solargraph::Pin::CompoundStatementable, nil]
            enclosing_compound_statement_pin = pins.select{|pin| pin.is_a?(Pin::CompoundStatementable) && pin.location.range.contain?(position)}.last
            FlowSensitiveTyping.new(locals,
                                    enclosing_breakable_pin,
                                    enclosing_compound_statement_pin).process_if(node)

            pins.push Solargraph::Pin::If.new(
              location: get_node_location(node),
              closure: region.closure,
              node: node,
              comments: comments_for(node),
              source: :parser,
            )
            process_children region
          end
        end
      end
    end
  end
end
