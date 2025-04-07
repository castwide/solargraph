# frozen_string_literal: true

module Solargraph
  module Pin
    class Callable < Closure
      attr_reader :parameters

      # @return [ComplexType, nil]
      attr_reader :return_type

      # @param return_type [ComplexType, nil]
      # @param parameters [::Array<Pin::Parameter>]
      def initialize return_type: nil, parameters: [], **splat
        super(**splat)
        @return_type = return_type
        @parameters = parameters
      end

      # @return [::Array<String>]
      def parameter_names
        @parameter_names ||= parameters.map(&:name)
      end

      def transform_types(&transform)
        c = super(&transform)
        c.parameters = c.parameters.map do |param|
          param.transform_types(&transform)
        end
        c
      end

      # @return [String]
      def to_rbs
        rbs_generics + '(' + parameters.map { |param| param.to_rbs }.join(', ') + ') ' + (block.nil? ? '' : '{ ' + block.to_rbs + ' } ') + '-> ' + return_type.to_rbs
      end

      protected

      attr_writer :parameters
    end
  end
end
