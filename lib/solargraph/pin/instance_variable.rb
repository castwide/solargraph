module Solargraph
  module Pin
    class InstanceVariable < BaseVariable
      def kind
        Pin::INSTANCE_VARIABLE
      end

      def scope
        @scope ||= (context.kind == Pin::NAMESPACE ? :class : context.scope)
      end
    end
  end
end
