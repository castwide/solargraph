module Solargraph
  module Pin
    class Signature < Base
      # @return [::Array<Parameter>]
      attr_reader :parameters

      # @return [ComplexType]
      attr_reader :return_type

      # @return [self]
      attr_reader :block

      # @param parameters [Array<Parameter>]
      # @param return_type [ComplexType]
      # @param block [Signature, nil]
      def initialize parameters, return_type, block = nil
        @parameters = parameters
        @return_type = return_type
        @block = block
      end

      def generics
        @generics ||= [].freeze
      end

      # @return [String]
      def to_rbs
        @rbs ||= rbs_generics + '(' + parameters.map { |param| param.to_rbs }.join(', ') + ') ' + (block.nil? ? '' : '{ ' + block.to_rbs + ' } ') + '-> ' + return_type.to_rbs
      end

      # @return [String]
      def rbs_generics
        if generics.empty?
          return ''
        else
          return '[' + generics.map { |gen| gen.to_s }.join(', ') + '] '
        end
      end

      # Probe the concrete type for each of the generic type
      # parameters used in this method, and return a new method pin if
      # possible.
      #
      # @param definitions [Pin::Namespace] The module/class which uses generic types
      # @param context_type [ComplexType] The receiver type, including the parameters
      #   we want to substitute into 'definitions'
      # @return [self]
      def resolve_generics definitions, context_type
        signature = super
        signature.parameters = signature.parameters.map do |param|
          param.resolve_generics(definitions, context_type)
        end
        signature.block = block.resolve_generics(definitions, context_type) if signature.block?
        signature.return_type = return_type.resolve_generics(definitions, context_type)
        signature
      end

      def identity
        @identity ||= "signature#{object_id}"
      end

      def block?
        !!@block
      end

      protected

      attr_writer :block

      attr_writer :parameters
    end
  end
end
