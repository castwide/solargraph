# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class OrNode < Parser::NodeProcessor::Base
          include ParserGem::NodeMethods

          def process
            process_children

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
