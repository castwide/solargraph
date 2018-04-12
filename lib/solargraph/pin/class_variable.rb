module Solargraph
  module Pin
    class ClassVariable < BaseVariable
      def kind
        Pin::CLASS_VARIABLE
      end
    end
  end
end
