# frozen_string_literal: true

module Solargraph
  module Pin
    class Closure < Base
      # @return [::Symbol] :class or :instance
      attr_reader :scope

      # @param scope [::Symbol] :class or :instance
      # @param generics [::Array<Pin::Parameter>, nil]
      def initialize scope: :class, generics: nil, **splat
        super(**splat)
        @scope = scope
        @generics = generics
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

      def binder
        @binder || context
      end

      # @return [::Array<String>]
      def gates
        # @todo This check might not be necessary. There should always be a
        #   root pin
        closure ? closure.gates : ['']
      end

      # @return [::Array<String>]
      def generics
        @generics ||= docstring.tags(:generic).map(&:name)
      end

      # @return [String]
      def to_rbs
        rbs_generics + return_type.to_rbs
      end

      # @return [String]
      def rbs_generics
        return '' if generics.empty?

        '[' + generics.map { |gen| gen.to_s }.join(', ') + '] '
      end

      include Logging
    end
  end
end
