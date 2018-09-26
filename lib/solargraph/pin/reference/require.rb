module Solargraph
  module Pin
    class Reference
      class Require < Reference
        def initialize location, name
          super(location, '', name)
        end

        def kind
          Pin::REQUIRE_REFERENCE
        end
      end
    end
  end
end
