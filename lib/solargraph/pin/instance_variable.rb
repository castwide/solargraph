# frozen_string_literal: true

module Solargraph
  module Pin
    class InstanceVariable < BaseVariable
      # @return [ComplexType]
      def binder
        closure.binder
      end

      # @return [::Symbol]
      def scope
        closure.binder.scope
      end

      # @return [ComplexType]
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

      # @param other [InstanceVariable]
      def nearly? other
        super && binder == other.binder
      end
    end
  end
end
