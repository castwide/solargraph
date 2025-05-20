# frozen_string_literal: true

module Solargraph
  module Pin
    class Reference
      class Require < Reference
        def initialize location, name, **splat
          # super(location, '', name)
          super(location: location, name: name, **splat)
        end
      end
    end
  end
end
