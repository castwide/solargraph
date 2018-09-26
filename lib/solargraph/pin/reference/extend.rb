module Solargraph
  module Pin
    class Reference
      class Extend < Reference
        def kind
          Pin::EXTEND_REFERENCE
        end
      end
    end
  end
end
