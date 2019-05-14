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

      def binder
        closure.binder
      end

      def context
        @context ||= begin
          result = super
          if scope == :class
            ComplexType.parse("Class<#{result.namespace}>")
          else
            ComplexType.parse("#{result.namespace}")
          end
        end
      end

      def nearly? other
        super && binder == other.binder
      end

      def try_merge! pin
        return false unless super
        @assignment = pin.assignment
        @return_type = pin.return_type
        true
      end
    end
  end
end
