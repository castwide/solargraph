# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class IfNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            process_children

            FlowSensitiveTyping.new(locals, enclosing_breakable_pin).process_if(node)
          end
        end
      end
    end
  end
end
