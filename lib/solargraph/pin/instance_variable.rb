module Solargraph
  module Pin
    class InstanceVariable < BaseVariable
      attr_reader :scope

      def kind
        Pin::INSTANCE_VARIABLE
      end

      def initialize scope: :instance, **splat
        super(splat)
        @scope = scope
      end

      def context
        @context ||= begin
          result = super
          if scope == :class
            ComplexType.parse("Class<#{result.namespace}>")
          else
            result
          end
        end
      end
    end
  end
end
