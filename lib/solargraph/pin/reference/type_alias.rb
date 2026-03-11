# frozen_string_literal: true

module Solargraph
  module Pin
    class Reference
      class TypeAlias < Reference
        # @param return_type [ComplexType]
        def initialize return_type:, **splat
          super(**splat)
          @return_type = return_type
        end
      end
    end
  end
end
