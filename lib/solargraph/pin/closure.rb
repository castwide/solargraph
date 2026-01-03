# frozen_string_literal: true

module Solargraph
  module Pin
    class Closure < CompoundStatement
      # @return [::Symbol] :class or :instance
      attr_reader :scope

      # @param scope [::Symbol] :class or :instance
      # @param generics [::Array<Pin::String>, nil]
      # @param generic_defaults [Hash{String => ComplexType}]
      def initialize scope: :class, generics: nil, generic_defaults: {},  **splat
        super(**splat)
        @scope = scope
        @generics = generics
        @generic_defaults = generic_defaults
      end

      # @return [Hash{String => ComplexType}]
      def generic_defaults
        @generic_defaults ||= {}
      end

      # @param other [self]
      # @param attrs [Hash{Symbol => Object}]
      #
      # @return [self]
      def combine_with(other, attrs={})
        new_attrs = {
          scope: assert_same(other, :scope),
          generics: generics.empty? ? other.generics : generics,
        }.merge(attrs)
        super(other, new_attrs)
      end

      def context
        @context ||= begin
          result = super
          if scope == :instance
            result.reduce_class_type
          else
            result
          end
        end
      end

      # @return [ComplexType, ComplexType::UniqueType]
      def binder
        @binder || context
      end

      # @param api_map [Solargraph::ApiMap]
      # @return [void]
      def rebind api_map; end

      # @return [::Array<String>]
      def generics
        @generics ||= docstring.tags(:generic).map(&:name)
      end

      def to_rbs
        rbs_generics + return_type.to_rbs
      end

      # @return [String]
      def rbs_generics
        return '' if generics.empty?

        '[' + generics.map { |gen| gen.to_s }.join(', ') + '] '
      end
    end
  end
end
