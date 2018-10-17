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
      autoload :Variable,         'solargraph/source/chain/variable'
      autoload :ClassVariable,    'solargraph/source/chain/class_variable'
      autoload :Constant,         'solargraph/source/chain/constant'
      autoload :InstanceVariable, 'solargraph/source/chain/instance_variable'
      autoload :GlobalVariable,   'solargraph/source/chain/global_variable'
      autoload :Literal,          'solargraph/source/chain/literal'
      autoload :Head,             'solargraph/source/chain/head'

      # Chain#infer uses the inference stack to avoid recursing into itself.
      # See Chain#active_signature for more information.
      @@inference_stack = []

      UNDEFINED_CALL = Chain::Call.new('<undefined>')
      UNDEFINED_CONSTANT = Chain::Constant.new('<undefined>')

      # @return [Array<Source::Chain::Link>]
      attr_reader :links

      # @param links [Array<Chain::Link>]
      def initialize links
        @links = links
        @links.push UNDEFINED_CALL if @links.empty?
      end

      # @return [Chain]
      def base
        @base ||= Chain.new(links[0..-2])
      end

      # @param api_map [ApiMap]
      # @param name_pin [Pin::Base]
      # @param locals [Array<Pin::Base>]
      # @return [Array<Pin::Base>]
      def define api_map, name_pin, locals
        return [] if undefined?
        working_pin = name_pin
        links[0..-2].each do |link|
          pins = link.resolve(api_map, working_pin, locals)
          # Locals are only used when resolving the first link
          locals = []
          type = infer_first_defined(pins, api_map)
          return [] if type.undefined?
          working_pin = Pin::ProxyType.anonymous(type)
        end
        links.last.resolve(api_map, working_pin, locals)
      end

      # @param api_map [ApiMap]
      # @param name_pin [Pin::Base]
      # @param locals [Array<Pin::Base>]
      # @return [ComplexType]
      def infer api_map, name_pin, locals
        return ComplexType::UNDEFINED if undefined? || @@inference_stack.include?(active_signature(name_pin))
        @@inference_stack.push active_signature(name_pin)
        type = ComplexType::UNDEFINED
        pins = define(api_map, name_pin, locals)
        pins.each do |pin|
          type = pin.infer(api_map)
          break unless type.undefined?
        end
        @@inference_stack.pop
        type
      end

      # @return [Boolean]
      def literal?
        links.last.is_a?(Chain::Literal)
      end

      # @return [Boolean]
      def undefined?
        links.any?(&:undefined?)
      end

      # @return [Boolean]
      def constant?
        links.last.is_a?(Chain::Constant)
      end

      private

      # Get a signature for this chain that includes the current context
      # where it's being analyzed. Chain#infer uses this value to detect
      # recursive inference into the same chain, e.g., when two variables
      # reference each other in their assignments.
      #
      # @param pin [Pin::Base] The named pin context
      # @return [String]
      def active_signature(pin)
        "#{pin.namespace}|#{links.map(&:word).join('.')}"
      end

      # @param pins [Array<Pin::Base>]
      # @param api_map [ApiMap]
      # @return [ComplexType]
      def infer_first_defined pins, api_map
        type = ComplexType::UNDEFINED
        pins.each do |pin|
          type = pin.infer(api_map)
          break unless type.undefined?
        end
        type
      end
    end
  end
end
