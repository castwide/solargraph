module Solargraph
  module Pin
    class InstanceVariable < BaseVariable
      attr_reader :scope

      def initialize location, namespace, name, docstring, assignment, literal, scope
        super(location, namespace, name, docstring, assignment, literal)
        @scope = scope
      end
    end
  end
end
