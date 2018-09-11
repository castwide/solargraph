module Solargraph
  module Pin
    module Reference
      class Extend < Reference
        def kind
          Pin::EXTEND_REFERENCE
        end
      end
    end
  end
end
