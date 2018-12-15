module Solargraph
  class SourceMap
    module NodeProcessor
      class SclassNode < Base
        def process
          process_children region.update(visibility: :public, scope: :class)
        end
      end
    end
  end
end
