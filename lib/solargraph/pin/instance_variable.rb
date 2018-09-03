module Solargraph
  module Pin
    class InstanceVariable < BaseVariable
      def kind
        Pin::INSTANCE_VARIABLE
      end
    end
  end
end
