# frozen_string_literal: true

module Solargraph
  module Pin
    class Callable < Closure
      attr_reader :parameters

      # @param parameters [::Array<Pin::Parameter>]
      def initialize parameters: [], **splat
        super(**splat)
        @parameters = parameters
      end

      # @return [::Array<String>]
      def parameter_names
        @parameter_names ||= parameters.map(&:name)
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
