# frozen_string_literal: true

module Solargraph
  module Parser
    module Legacy
      module NodeProcessor
        class BeginNode < Base
          def process
            process_children
          end
        end
      end
    end
  end
end
