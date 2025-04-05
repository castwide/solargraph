# frozen_string_literal: true

module Solargraph
  module Pin
    class Closure < Base
      # @return [::Symbol] :class or :instance
      attr_reader :scope

      attr_reader :parameters

      # @param scope [::Symbol] :class or :instance
      # @param generics [::Array<Pin::Parameter>, nil]
      # @param parameters [::Array<Pin::Parameter>]
      def initialize scope: :class, generics: nil, parameters: [], **splat
        super(**splat)
        @scope = scope
        @generics = generics
        @parameters = parameters
      end

      def transform_types(&transform)
        c = super(&transform)
        c.parameters = c.parameters.map do |param|
          param.transform_types(&transform)
        end
        c
      end

      # @return [::Array<String>]
      def parameter_names
        @parameter_names ||= parameters.map(&:name)
      end

      def context
        @context ||= begin
          result = super
          if scope == :instance
            Solargraph::ComplexType.parse(result.namespace)
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
        rbs_generics + '(' + parameters.map { |param| param.to_rbs }.join(', ') + ') ' + (block.nil? ? '' : '{ ' + block.to_rbs + ' } ') + '-> ' + return_type.to_rbs
      end

      # @return [String]
      def rbs_generics
        return '' if generics.empty?

        '[' + generics.map { |gen| gen.to_s }.join(', ') + '] '
      end

      protected

      attr_writer :parameters
    end
  end
end
