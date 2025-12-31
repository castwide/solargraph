# frozen_string_literal: true

module Solargraph
  module Pin
    class Callable < Closure
      # @return [Signature]
      attr_reader :block

      attr_accessor :parameters

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

      def reset_generated!
        parameters.each(&:reset_generated!)
        super
      end

      # @return [String]
      def method_namespace
        closure.namespace
      end

      # @param other [self]
      #
      # @return [Pin::Signature, nil]
      def combine_blocks(other)
        if block.nil?
          other.block
        elsif other.block.nil?
          block
        else
          # @type [Pin::Signature, nil]
          choose_pin_attr(other, :block)
        end
      end

      # @param other [self]
      # @param attrs [Hash{Symbol => Object}]
      #
      # @return [self]
      def combine_with(other, attrs={})
        new_attrs = {
          block: combine_blocks(other),
          return_type: combine_return_type(other),
        }.merge(attrs)
        new_attrs[:parameters] = choose_parameters(other).clone.freeze unless new_attrs.key?(:parameters)
        super(other, new_attrs)
      end

      # @return [::Array<String>]
      def parameter_names
        @parameter_names ||= parameters.map(&:name)
      end

      def generics
        []
      end

      # @param other [self]
      #
      # @return [Array<Pin::Parameter>]
      def choose_parameters(other)
        raise "Trying to combine two pins with different arities - \nself =#{inspect}, \nother=#{other.inspect}, \n\n self.arity=#{self.arity}, \nother.arity=#{other.arity}" if other.arity != arity
        # @param param [Pin::Parameter]
        # @param other_param [Pin::Parameter]
        parameters.zip(other.parameters).map do |param, other_param|
          if param.nil? && other_param.block?
            other_param
          elsif other_param.nil? && param.block?
            param
          else
            param.combine_with(other_param)
          end
        end
      end

      # @return [Array<Pin::Parameter>]
      def blockless_parameters
        if parameters.last&.block?
          parameters[0..-2]
        else
          parameters
        end
      end

      # @return [Array]
      def arity
        [generics, blockless_parameters.map(&:arity_decl), block&.arity]
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

      def typify api_map
        type = super
        return type if type.defined?
        if method_name.end_with?('?')
          logger.debug { "Callable#typify(self=#{self}) => Boolean (? suffix)" }
          ComplexType::BOOLEAN
        else
          logger.debug { "Callable#typify(self=#{self}) => undefined" }
          ComplexType::UNDEFINED
        end
      end

      # @return [String]
      def method_name
        raise "closure was nil in #{self.inspect}" if closure.nil?
        @method_name ||= closure.name
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

      # @return [Integer]
      def mandatory_positional_param_count
        parameters.count(&:arg?)
      end

      def to_rbs
        rbs_generics + '(' + parameters.map { |param| param.to_rbs }.join(', ') + ') ' + (block.nil? ? '' : '{ ' + block.to_rbs + ' } ') + '-> ' + return_type.to_rbs
      end

      def block?
        !!@block
      end

      protected

      attr_writer :block
    end
  end
end
