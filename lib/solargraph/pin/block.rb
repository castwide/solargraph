# frozen_string_literal: true

module Solargraph
  module Pin
    class Block < Callable
      # @return [Parser::AST::Node]
      attr_reader :receiver

      # @return [Parser::AST::Node]
      attr_reader :node

      # @param receiver [Parser::AST::Node, nil]
      # @param node [Parser::AST::Node, nil]
      # @param context [ComplexType, nil]
      # @param args [::Array<Parameter>]
      def initialize receiver: nil, args: [], context: nil, node: nil, **splat
        super(**splat, parameters: args)
        @receiver = receiver
        @context = context
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

      # @param api_map [ApiMap]
      # @return [::Array<ComplexType>]
      def typify_parameters(api_map)
        logger.debug("Block#typify_parameters() - start")
        chain = Parser.chain(receiver, filename, node)
        logger.debug { "Block#typify_parameters() - chain=#{chain.desc}" }
        clip = api_map.clip_at(location.filename, location.range.start)
        locals = clip.locals - [self]
        meths = chain.define(api_map, closure, locals)
        logger.debug { "Block#typify_parameters() - meths=#{meths}" }
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
                after_generics = arg_type.resolve_generics(namespace_pin, param_type)
                logger.debug { "Block#typify_parameters() - arg_type=#{arg_type}, namespace_pin=#{namespace_pin}, param_type=#{param_type}, after_generics=#{after_generics}" }
                after_generics
              else
                arg_type.self_to_type(chain.base.infer(api_map, self, locals)).qualify(api_map, meth.context.namespace)
              end
            end
          end
          if param_types.all?(&:defined?)
            logger.debug { "Block#typify_parameters() => #{param_types.map(&:rooted_tags)}" }
            return param_types
          else
            logger.debug { "Block#typify_parameters() - param_types=#{param_types.map(&:rooted_tags)}" }
          end
        end
        out = parameters.map { ComplexType::UNDEFINED }
        logger.debug { "Block#typify_parameters() => #{out.map(&:rooted_tags)}" }
        out
      end

      private

      # @param api_map [ApiMap]
      # @return [ComplexType]
      def maybe_rebind api_map
        return ComplexType::UNDEFINED unless receiver

        chain = Parser.chain(receiver, location.filename)
        locals = api_map.source_map(location.filename).locals_at(location)
        receiver_pin = chain.define(api_map, closure, locals).first
        return ComplexType::UNDEFINED unless receiver_pin

        types = receiver_pin.docstring.tag(:yieldreceiver)&.types
        return ComplexType::UNDEFINED unless types&.any?

        target = chain.base.infer(api_map, receiver_pin, locals)
        target = full_context unless target.defined?

        ComplexType.try_parse(*types).qualify(api_map, receiver_pin.context.namespace).self_to_type(target)
      end
    end
  end
end
