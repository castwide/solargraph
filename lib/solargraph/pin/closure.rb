module Solargraph
  module Pin
    class Closure < Base
      def binder
        @binder || context
      end
    end
  end
end
