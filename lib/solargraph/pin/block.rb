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
        @node = node
      end

      # @param api_map [ApiMap]
      # @return [void]
      def rebind api_map
        @binder ||= binder_or_nil(api_map)
      end

      def binder
        @binder || closure.binder
      end

      # @return [::Array<Parameter>]
      def parameters
        @parameters ||= []
      end

      # @return [::Array<String>]
      def parameter_names
        @parameter_names ||= parameters.map(&:name)
      end

      private

      # @param api_map [ApiMap]
      # @return [ComplexType, nil]
      def binder_or_nil api_map
        return nil unless receiver

        chain = Parser.chain(receiver, location.filename)
        locals = api_map.source_map(location.filename).locals_at(location)
        receiver_pin = chain.define(api_map, self, locals).first
        return nil unless receiver_pin

        types = receiver_pin.docstring.tag(:yieldreceiver)&.types
        return nil unless types&.any?

        target = chain.base.infer(api_map, receiver_pin, locals)
        target = full_context unless target.defined?

        ComplexType.try_parse(*types).qualify(api_map, receiver_pin.context.namespace).self_to(target.to_s)
      end
    end
  end
end
