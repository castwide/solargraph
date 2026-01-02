# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      module NodeProcessors
        class BeginNode < Parser::NodeProcessor::Base
          def process
            # We intentionally don't create a CompoundStatement pin
            # here, as this is not necessarily a control flow block -
            # e.g., a begin...end without rescue or ensure should be
            # treated by flow-sensitive typing as if the begin and end
            # didn't exist at all.  As such, we create the
            # CompoundStatement pins around the things which actually
            # result in control flow changes - like
            # if/while/rescue/etc

            process_children
          end
        end
      end
    end
  end
end
