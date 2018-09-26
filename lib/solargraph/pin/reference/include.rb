module Solargraph
  module Pin
    class Reference
      class Include < Reference
        def kind
          Pin::INCLUDE_REFERENCE
        end
      end
    end
  end
end
