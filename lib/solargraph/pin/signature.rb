module Solargraph
  module Pin
    class Signature < Base
      # @return [::Array<Parameter>]
      attr_reader :parameters

      # @return [ComplexType]
      attr_reader :return_type

      # @return [self]
      attr_reader :block

      # @return [Array<String>]
      attr_reader :generics

      # @param generics [Array<String>]
      # @param parameters [Array<Parameter>]
      # @param return_type [ComplexType]
      # @param block [Signature, nil]
      def initialize generics, parameters, return_type, block = nil
        @generics = generics
        @parameters = parameters
        @return_type = return_type
        @block = block
      end

      # @yieldparam [ComplexType]
      # @yieldreturn [ComplexType]
      # @return [self]
      def transform_types(&transform)
        # @todo 'super' alone should work here I think, but doesn't typecheck at level typed
        signature = super(&transform)
        signature.parameters = signature.parameters.map do |param|
          param.transform_types(&transform)
        end
        signature.block = block.transform_types(&transform) if signature.block?
        signature
      end

      # @param arg_types [Array<ComplexType>, nil]
      # @param return_type_context [ComplexType, nil]
      # @param yield_arg_types [Array<ComplexType>, nil]
      # @param yield_return_type_context [ComplexType, nil]
      # @param context [ComplexType, nil]
      # @param resolved_generic_values [Hash{String => ComplexType}]
      # @return [self]
      def resolve_generics_from_context(arg_types = nil,
                                        return_type_context = nil,
                                        yield_arg_types = nil,
                                        yield_return_type_context = nil,
                                        resolved_generic_values: {})
        signature = super(return_type_context, resolved_generic_values:)
        signature.parameters = signature.parameters.each_with_index.map do |param, i|
          if arg_types.nil?
            param.dup
          else
            param.resolve_generics_from_context(arg_types[i], resolved_generic_values:)
          end
        end
        signature.block = block.resolve_generics_from_context(yield_arg_types, yield_return_type_context, resolved_generic_values) if signature.block?
        signature
      end

      # @param arg_types [Array<ComplexType>, nil]
      # @param return_type_context [ComplexType, nil]
      # @param yield_arg_types [Array<ComplexType>, nil]
      # @param yield_return_type_context [ComplexType, nil]
      # @param context [ComplexType, nil]
      # @param resolved_generic_values [Hash{String => ComplexType}]
      # @return [self]
      # TODO: See note in UniqueType and match interface
      # TODO: This doesn't currently limit its resolution to the generics defined on the method.
      # TODO: Worth looking into what the RBS spec says if anything about generics - is there a resolution algorithm specified?  What do steep and sorbet do?
      def resolve_generics_from_context_until_complete(arg_types,
                                                       return_type_context = nil,
                                                       yield_arg_types = nil,
                                                       yield_return_type_context = nil,
                                                       resolved_generic_values: {})
        last_resolved_generic_values = resolved_generic_values.dup
        new_pin = resolve_generics_from_context(arg_types,
                                                return_type_context,
                                                yield_arg_types,
                                                yield_return_type_context,
                                                resolved_generic_values:)
        if last_resolved_generic_values == resolved_generic_values
          # erase anything unresolved
          return new_pin.erase_generics(generics)
        end
        new_pin.resolve_generics_from_context_until_complete(arg_types,
                                                             return_type_context,
                                                             yield_arg_types,
                                                             yield_return_type_context,
                                                             resolved_generic_values:)
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
