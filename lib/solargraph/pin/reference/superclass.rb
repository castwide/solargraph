# frozen_string_literal: true

module Solargraph
  module Pin
    class Reference
      # A Superclass reference pin.
      #
      class Superclass < Reference
        # @sg-ignore pin.closure relies on closure always resolved
        def reference_gates
          # @sg-ignore pin.closure relies on closure always resolved
          @reference_gates ||= closure.gates - [closure.path]
        end
      end
    end
  end
end
