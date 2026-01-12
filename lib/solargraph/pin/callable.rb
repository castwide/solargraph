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

      # @sg-ignore Need to add nil check here
      # @return [String]
      def method_namespace
        # @sg-ignore Need to add nil check here
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

      # @sg-ignore Need to add nil check here
      # @return [Array<Pin::Parameter>]
      def blockless_parameters
        if parameters.last&.block?
          parameters[0..-2]
        else
          parameters
        end
      end

      # e.g., [["T"], "", "?", "foo:"] - parameter arity declarations,
      #   ignoring positional names.  Used to match signatures.
      #
      # @return [Array<Array<String>, String, nil>]
      def arity
        [generics, blockless_parameters.map(&:arity_decl), block&.arity]
      end

      # e.g., [["T"], "1", "?3", "foo:5"] - parameter arity
      #   declarations, including the number of unique types in each
      #   parameter.  Used to determine whether combining two
      #   signatures has lost useful information mapping specific
      #   parameter types to specific return types.
      #
      # @return [Array<Array, String, nil>]
      def type_arity
        [generics, blockless_parameters.map(&:type_arity_decl), block&.type_arity]
      end

      # Same as type_arity, but includes return type arity at the front.
      #
      # @return [Array<Array, String, nil>]
      def full_type_arity
        # @sg-ignore flow sensitive typing needs to handle attrs
        [return_type ? return_type.items.count.to_s : nil] + type_arity
      end

      # @param generics_to_resolve [Enumerable<String>]
      # @param arg_types [Array<ComplexType>, nil]
      # @param return_type_context [ComplexType, nil]
      # @param yield_arg_types [Array<ComplexType>, nil]
      # @param yield_return_type_context [ComplexType, nil]
      # @param context [ComplexType, nil]
      # @param resolved_generic_values [Hash{String => ComplexType}]
      #
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

      # @sg-ignore Need to add nil check here
      # @return [String]
      def method_name
        raise "closure was nil in #{self.inspect}" if closure.nil?
        # @sg-ignore Need to add nil check here
        @method_name ||= closure.name
      end

      # @param generics_to_resolve [::Array<String>]
      # @param arg_types [Array<ComplexType>, nil]
      # @param return_type_context [ComplexType, nil]
      # @param yield_arg_types [Array<ComplexType>, nil]
      # @param yield_return_type_context [ComplexType, nil]
      # @param context [ComplexType, nil]
      # @param resolved_generic_values [Hash{String => ComplexType}]
      #
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
        # @todo this and its caller should be changed so that this can
        #   look at the kwargs provided and check names against what
        #   we acccept
        return false if argcount < parcount && !(argcount == parcount - 1 && parameters.last.restarg?)
        true
      end

      def reset_generated!
        super
        @parameters.each(&:reset_generated!)
      end

      # @return [Integer]
      def mandatory_positional_param_count
        parameters.count(&:arg?)
      end

      # @return [String]
      def parameters_to_rbs
        # @sg-ignore Need to add nil check here
        rbs_generics + '(' + parameters.map { |param| param.to_rbs }.join(', ') + ') ' + (block.nil? ? '' : '{ ' + block.to_rbs + ' } ')
      end

      def to_rbs
        parameters_to_rbs + '-> ' + (return_type&.to_rbs || 'untyped')
      end

      def block?
        !!@block
      end

      protected

      attr_writer :block
    end
  end
end
