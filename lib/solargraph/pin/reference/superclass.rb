# frozen_string_literal: true

module Solargraph
  module Pin
    class Reference
      class Superclass < Reference
        def reference_gates
          @reference_gates ||= closure.gates - [closure.path]
        end
      end
    end
  end
end
