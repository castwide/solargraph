module Solargraph
  class SourceMap
    module NodeProcessor
      class BeginNode < Base
        def process
          process_children
        end
      end
    end
  end
end
