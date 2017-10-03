module Solargraph
  module Pin
    class InstanceVariable < BaseVariable
      attr_reader :scope

      def initialize source, node, namespace, scope
        super(source, node, namespace)
        @scope = scope
      end
    end
  end
end
