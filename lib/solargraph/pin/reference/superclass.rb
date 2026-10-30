# frozen_string_literal: true

module Solargraph
  module Pin
    class Reference
      # A Superclass reference pin.
      #
      class Superclass < Reference
        # @sg-ignore https://github.com/castwide/solargraph/pull/1393
        def reference_gates
          # @sg-ignore https://github.com/castwide/solargraph/pull/1393
          @reference_gates ||= closure.gates - [closure.path]
        end
      end
    end
  end
end
