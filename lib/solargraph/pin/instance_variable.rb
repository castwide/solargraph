module Solargraph
  module Pin
    class InstanceVariable < BaseVariable
      attr_reader :scope

      def initialize location, namespace, name, docstring, assignment, literal, scope
        super(location, namespace, name, docstring, assignment, literal)
        @scope = scope
      end

      def kind
        Pin::INSTANCE_VARIABLE
      end
    end
  end
end
