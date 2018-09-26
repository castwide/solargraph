module Solargraph
  module Pin
    class Reference
      class Superclass < Reference
        def kind
          Pin::SUPERCLASS_REFERENCE
        end
      end
    end
  end
end
