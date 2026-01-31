# frozen_string_literal: true

module Solargraph
  module Pin
    class Reference
      # A Superclass reference pin.
      #
      class Superclass < Reference
        # @sg-ignore Need to add nil check here
        def reference_gates
          # @sg-ignore Need to add nil check here
          @reference_gates ||= closure.gates - [closure.path]
        end
      end
    end
  end
end
