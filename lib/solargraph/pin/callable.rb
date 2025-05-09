# frozen_string_literal: true

module Solargraph
  module Pin
    class Callable < Closure
      # @return [Signature]
      attr_reader :block

      attr_reader :parameters

      # @return [ComplexType, nil]
      attr_reader :return_type

      # @param block [Signature, nil]
      # @param return_type [ComplexType, nil]
      # @param parameters [::Array<Pin::Parameter>]
      def initialize block: nil, return_type: nil, parameters: [], **splat
        super(**splat)
        @block = block
        @return_type = return_type
        @parameters = parameters
      end

      # @return [::Array<String>]
      def parameter_names
        @parameter_names ||= parameters.map(&:name)
      end

      # @param generics_to_resolve [Enumerable<String>]
      # @param arg_types [Array<ComplexType>, nil]
      # @param return_type_context [ComplexType, nil]
      # @param yield_arg_types [Array<ComplexType>, nil]
      # @param yield_return_type_context [ComplexType, nil]
      # @param context [ComplexType, nil]
      # @param resolved_generic_values [Hash{String => ComplexType}]
      # @return [self]
      def resolve_generics_from_context(generics_to_resolve,
                                        arg_types = nil,
                                        return_type_context = nil,
                                        yield_arg_types = nil,
                                        yield_return_type_context = nil,
                                        resolved_generic_values: {})
        callable = super(generics_to_resolve, return_type_context, resolved_generic_values: resolved_generic_values)
        callable.parameters = callable.parameters.each_with_index.map do |param, i|
          if arg_types.nil?
            param.dup
          else
            param.resolve_generics_from_context(generics_to_resolve,
                                                arg_types[i],
                                                resolved_generic_values: resolved_generic_values)
          end
        end
        callable.block = block.resolve_generics_from_context(generics_to_resolve,
                                                              yield_arg_types,
                                                              yield_return_type_context,
                                                              resolved_generic_values: resolved_generic_values) if callable.block?
        callable
      end

      # @param generics_to_resolve [::Array<String>]
      # @param arg_types [Array<ComplexType>, nil]
      # @param return_type_context [ComplexType, nil]
      # @param yield_arg_types [Array<ComplexType>, nil]
      # @param yield_return_type_context [ComplexType, nil]
      # @param context [ComplexType, nil]
      # @param resolved_generic_values [Hash{String => ComplexType}]
      # @return [self]
      def resolve_generics_from_context_until_complete(generics_to_resolve,
                                                       arg_types = nil,
                                                       return_type_context = nil,
                                                       yield_arg_types = nil,
                                                       yield_return_type_context = nil,
                                                       resolved_generic_values: {})
        # See
        # https://github.com/soutaro/steep/tree/master/lib/steep/type_inference
        # and
        # https://github.com/sorbet/sorbet/blob/master/infer/inference.cc
        # for other implementations

        return self if generics_to_resolve.empty?

        last_resolved_generic_values = resolved_generic_values.dup
        new_pin = resolve_generics_from_context(generics_to_resolve,
                                                arg_types,
                                                return_type_context,
                                                yield_arg_types,
                                                yield_return_type_context,
                                                resolved_generic_values: resolved_generic_values)
        if last_resolved_generic_values == resolved_generic_values
          # erase anything unresolved
          return new_pin.erase_generics(self.generics)
        end
        new_pin.resolve_generics_from_context_until_complete(generics_to_resolve,
                                                             arg_types,
                                                             return_type_context,
                                                             yield_arg_types,
                                                             yield_return_type_context,
                                                             resolved_generic_values: resolved_generic_values)
      end

      # @return [Array<String>]
      # @yieldparam [ComplexType]
      # @yieldreturn [ComplexType]
      # @return [self]
      def transform_types(&transform)
        # @todo 'super' alone should work here I think, but doesn't typecheck at level typed
        callable = super(&transform)
        callable.block = block.transform_types(&transform) if block?
        callable.parameters = parameters.map do |param|
          param.transform_types(&transform)
        end
        callable
      end

      # @param arguments [::Array<Chain>]
      # @param with_block [Boolean]
      # @return [Boolean]
      def arity_matches? arguments, with_block
        argcount = arguments.length
        parcount = mandatory_positional_param_count
        parcount -= 1 if !parameters.empty? && parameters.last.block?
        return false if block? && !with_block
        return false if argcount < parcount && !(argcount == parcount - 1 && parameters.last.restarg?)
        true
      end

      def mandatory_positional_param_count
        parameters.count(&:arg?)
      end

      # @return [String]
      def to_rbs
        rbs_generics + '(' + parameters.map { |param| param.to_rbs }.join(', ') + ') ' + (block.nil? ? '' : '{ ' + block.to_rbs + ' } ') + '-> ' + return_type.to_rbs
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
