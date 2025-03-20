# frozen_string_literal: true

# HACK: Fix autoload issue
require 'solargraph/source/chain/link'

module Solargraph
  class Source
    # A chain of constants, variables, and method calls for inferring types of
    # values.
    #
    class Chain
      autoload :Link,             'solargraph/source/chain/link'
      autoload :Call,             'solargraph/source/chain/call'
      autoload :QCall,            'solargraph/source/chain/q_call'
      autoload :Variable,         'solargraph/source/chain/variable'
      autoload :ClassVariable,    'solargraph/source/chain/class_variable'
      autoload :Constant,         'solargraph/source/chain/constant'
      autoload :InstanceVariable, 'solargraph/source/chain/instance_variable'
      autoload :GlobalVariable,   'solargraph/source/chain/global_variable'
      autoload :Literal,          'solargraph/source/chain/literal'
      autoload :Head,             'solargraph/source/chain/head'
      autoload :Or,               'solargraph/source/chain/or'
      autoload :BlockVariable,    'solargraph/source/chain/block_variable'
      autoload :ZSuper,           'solargraph/source/chain/z_super'
      autoload :Hash,             'solargraph/source/chain/hash'
      autoload :Array,            'solargraph/source/chain/array'

      @@inference_stack = []
      @@inference_depth = 0

      UNDEFINED_CALL = Chain::Call.new('<undefined>')
      UNDEFINED_CONSTANT = Chain::Constant.new('<undefined>')

      # @return [::Array<Source::Chain::Link>]
      attr_reader :links

      attr_reader :node

      # @param node [Parser::AST::Node, nil]
      # @param links [::Array<Chain::Link>]
      # @param splat [Boolean]
      def initialize links, node = nil, splat = false
        @links = links.clone
        @links.push UNDEFINED_CALL if @links.empty?
        head = true
        @links.map! do |link|
          result = (head ? link.clone_head : link.clone_body)
          head = false
          result
        end
        @node = node
        @splat = splat
      end

      # @return [Chain]
      def base
        @base ||= Chain.new(links[0..-2])
      end

      # @param api_map [ApiMap]
      # @param name_pin [Pin::Base]
      # @param locals [::Enumerable<Pin::LocalVariable>]
      #
      # @return [::Array<Pin::Base>]
      def define api_map, name_pin, locals
        return [] if undefined?
        working_pin = name_pin
        links[0..-2].each do |link|
          pins = link.resolve(api_map, working_pin, locals)
          type = infer_first_defined(pins, working_pin, api_map, locals)
          return [] if type.undefined?
          working_pin = Pin::ProxyType.anonymous(type)
        end
        links.last.last_context = name_pin
        links.last.resolve(api_map, working_pin, locals)
      end

      # @param api_map [ApiMap]
      # @param name_pin [Pin::Base]
      # @param locals [::Enumerable<Pin::LocalVariable>]
      # @return [ComplexType]
      def infer api_map, name_pin, locals
        from_here = base.infer(api_map, name_pin, locals) unless links.length == 1
        if from_here
          name_pin = name_pin.proxy(from_here)
        end
        pins = define(api_map, name_pin, locals)
        type = infer_first_defined(pins, links.last.last_context, api_map, locals)
        maybe_nil(type)
      end

      # @return [Boolean]
      def literal?
        links.last.is_a?(Chain::Literal)
      end

      def undefined?
        links.any?(&:undefined?)
      end

      def defined?
        !undefined?
      end

      # @return [Boolean]
      def constant?
        links.last.is_a?(Chain::Constant)
      end

      def splat?
        @splat
      end

      def nullable?
        links.any?(&:nullable?)
      end

      private

      # @param pins [::Array<Pin::Base>]
      # @param context [Pin::Base]
      # @param api_map [ApiMap]
      # @param locals [::Enumerable<Pin::LocalVariable>]
      # @return [ComplexType]
      def infer_first_defined pins, context, api_map, locals
        possibles = []
        # @todo this param tag shouldn't be needed to probe the type
        # @todo ...but given it is needed, typecheck should complain that it is needed
        # @param pin [Pin::Base]
        pins.each do |pin|
          # Avoid infinite recursion
          next if @@inference_stack.include?(pin.identity)

          @@inference_stack.push pin.identity
          type = pin.typify(api_map)
          @@inference_stack.pop
          if type.defined?
            if type.generic?
              # @todo even at strong, no typechecking complaint
              #   happens when a [Pin::Base,nil] is passed into a method
              #   that accepts only [Pin::Namespace] as an argument
              type = type.resolve_generics(pin.closure, context.return_type)
            end
            if type.defined?
              possibles.push type
              break if pin.is_a?(Pin::Method)
            end
          end
        end
        if possibles.empty?
          # Limit method inference recursion
          return ComplexType::UNDEFINED if @@inference_depth >= 10 && pins.first.is_a?(Pin::Method)

          @@inference_depth += 1
          # @param pin [Pin::Base]
          pins.each do |pin|
            # Avoid infinite recursion
            next if @@inference_stack.include?(pin.identity)

            @@inference_stack.push pin.identity
            type = pin.probe(api_map)
            @@inference_stack.pop
            if type.defined?
              possibles.push type
              break if pin.is_a?(Pin::Method)
            end
          end
          @@inference_depth -= 1
        end
        return ComplexType::UNDEFINED if possibles.empty?
        type = if possibles.length > 1
          sorted = possibles.map { |t| t.rooted? ? "::#{t}" : t.to_s }.sort { |a, _| a == 'nil' ? 1 : 0 }
          ComplexType.parse(*sorted)
        else
          ComplexType.parse(possibles.map(&:to_s).join(', '))
        end
        return type if context.nil? || context.return_type.undefined?
        type.self_to(context.return_type.tag)
      end

      # @param type [ComplexType]
      # @return [ComplexType]
      def maybe_nil type
        return type if type.undefined? || type.void? || type.nullable?
        return type unless nullable?
        ComplexType.try_parse("#{type}, nil")
      end
    end
  end
end
