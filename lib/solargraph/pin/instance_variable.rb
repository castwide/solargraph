# frozen_string_literal: true

module Solargraph
  module Pin
    class InstanceVariable < BaseVariable
      # @sg-ignore https://github.com/castwide/solargraph/pull/1393
      # @return [ComplexType, ComplexType::UniqueType]
      def binder
        # @sg-ignore https://github.com/castwide/solargraph/pull/1393
        closure.binder
      end

      # @sg-ignore https://github.com/castwide/solargraph/pull/1393
      # @return [::Symbol]
      def scope
        # @sg-ignore https://github.com/castwide/solargraph/pull/1393
        closure.binder.scope
      end

      # @return [ComplexType]
      def context
        @context ||= begin
          result = super
          if scope == :class
            ComplexType.parse("::Class<#{result.rooted_namespace}>")
          else
            result.reduce_class_type
          end
        end
      end

      # @param other [InstanceVariable]
      def nearly? other
        super && binder == other.binder
      end
    end
  end
end
