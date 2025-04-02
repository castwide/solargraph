# frozen_string_literal: true

module Solargraph
  module Pin
    class Block < Closure
      # @return [Parser::AST::Node]
      attr_reader :receiver

      # @return [Parser::AST::Node]
      attr_reader :node

      # @param receiver [Parser::AST::Node, nil]
      # @param node [Parser::AST::Node, nil]
      # @param context [ComplexType, nil]
      # @param args [::Array<Parameter>]
      def initialize receiver: nil, args: [], context: nil, node: nil, **splat
        super(**splat)
        @receiver = receiver
        @context = context
        @parameters = args
        @return_type = ComplexType.parse('::Proc')
        @node = node
      end

      # @param api_map [ApiMap]
      # @return [void]
      def rebind api_map
        @rebind ||= maybe_rebind(api_map)
      end

      def binder
        @rebind&.defined? ? @rebind : closure.binder
      end

      # @return [::Array<Parameter>]
      def parameters
        @parameters ||= []
      end

      # @return [::Array<String>]
      def parameter_names
        @parameter_names ||= parameters.map(&:name)
      end

      # @param yield_types [::Array<ComplexType>]
      # @param parameters [::Array<Parameter>]
      #
      # @return [::Array<ComplexType>]
      def destructure_yield_types(yield_types, parameters)
        return yield_types if yield_types.length == parameters.length

        # yielding a tuple into a block will destructure the tuple
        if yield_types.length == 1
          yield_type = yield_types.first
          return yield_type.all_params if yield_type.tuple? && yield_type.all_params.length == parameters.length
        end
        parameters.map { ComplexType::UNDEFINED }
      end

      # @todo the next step with parameters, arguments, destructuring,
      #   kwargs, etc logic is probably either creating a Parameters
      #   or Callable pin that encapsulates and shares the logic
      #   between methods, blocks and signatures.  It could live in
      #   Signature if Method didn't also own potentially different
      #   set of parameters, generics and return types.

      # @param api_map [ApiMap]
      # @return [::Array<ComplexType>]
      def typify_parameters(api_map)
        chain = Parser.chain(receiver, filename, node)
        clip = api_map.clip_at(location.filename, location.range.start)
        locals = clip.locals - [self]
        meths = chain.define(api_map, closure, locals)
        # @todo Convert logic to use signatures
        meths.each do |meth|
          next if meth.block.nil?

          yield_types = meth.block.parameters.map(&:return_type)
          # 'arguments' is what the method says it will yield to the
          # block; 'parameters' is what the block accepts
          argument_types = destructure_yield_types(yield_types, parameters)
          param_types = argument_types.each_with_index.map do |arg_type, idx|
            param = parameters[idx]
            param_type = chain.base.infer(api_map, param, locals)
            unless arg_type.nil?
              if arg_type.generic? && param_type.defined?
                namespace_pin = api_map.get_namespace_pins(meth.namespace, closure.namespace).first
                arg_type.resolve_generics(namespace_pin, param_type)
              else
                arg_type.self_to(chain.base.infer(api_map, self, locals).namespace).qualify(api_map, meth.context.namespace)
              end
            end
          end
          return param_types if param_types.all?(&:defined?)
        end
        parameters.map { ComplexType::UNDEFINED }
      end

      private

      # @param api_map [ApiMap]
      # @return [ComplexType]
      def maybe_rebind api_map
        return ComplexType::UNDEFINED unless receiver

        chain = Parser.chain(receiver, location.filename)
        locals = api_map.source_map(location.filename).locals_at(location)
        receiver_pin = chain.define(api_map, self, locals).first
        return ComplexType::UNDEFINED unless receiver_pin

        types = receiver_pin.docstring.tag(:yieldreceiver)&.types
        return ComplexType::UNDEFINED unless types&.any?

        target = chain.base.infer(api_map, receiver_pin, locals)
        target = full_context unless target.defined?

        ComplexType.try_parse(*types).qualify(api_map, receiver_pin.context.namespace).self_to(target.to_s)
      end
    end
  end
end
