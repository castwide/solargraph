# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class OrNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          on_node_type_leave :or, :process

          def process
            FlowSensitiveTyping.new(locals,
                                    ivars,
                                    enclosing_breakable_pin,
                                    enclosing_compound_statement_pin).process_or(node)
          end
        end
      end
    end
  end
end
