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
        rebind_block name_pin, api_map, locals
        return [] if undefined?
        working_pin = name_pin
        links[0..-2].each do |link|
          pins = link.resolve(api_map, working_pin, locals)
          # Locals are only used when resolving the first link
          locals = []
          type = infer_first_defined(pins, api_map)
          return [] if type.undefined?
          if type.tag == 'self'
            working_pin = Pin::ProxyType.anonymous(ComplexType.try_parse(working_pin.return_type.namespace))
          else
            working_pin = Pin::ProxyType.anonymous(type)
          end
        end
        links.last.resolve(api_map, working_pin, locals)
      end

      # @param api_map [ApiMap]
      # @param name_pin [Pin::Base]
      # @param locals [Array<Pin::Base>]
      # @return [ComplexType]
      def infer api_map, name_pin, locals
        rebind_block name_pin, api_map, locals
        return ComplexType::UNDEFINED if undefined? || @@inference_stack.include?(active_signature(name_pin))
        @@inference_stack.push active_signature(name_pin)
        type = ComplexType::UNDEFINED
        pins = define(api_map, name_pin, locals)
        pins.each do |pin|
          type = pin.typify(api_map)
          break unless type.undefined?
        end
        type = pins.first.probe(api_map) unless type.defined? || pins.empty?
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
        "#{pin.path}|#{links.map(&:word).join('.')}"
      end

      # @param pins [Array<Pin::Base>]
      # @param api_map [ApiMap]
      # @return [ComplexType]
      def infer_first_defined pins, api_map
        type = ComplexType::UNDEFINED
        pins.each do |pin|
          # type = pin.infer(api_map)
          type = pin.typify(api_map)
          break unless type.undefined?
        end
        type = pins.first.probe(api_map) unless type.defined? || pins.empty?
        type
      end

      def skippable_block_receivers api_map
        @@skippable_block_receivers ||= (
          api_map.get_methods('Array', deep: false).map(&:name) +
          api_map.get_methods('Enumerable', deep: false).map(&:name) +
          api_map.get_methods('Hash', deep: false).map(&:name) +
          ['new']
        ).to_set
      end

      def rebind_block pin, api_map, locals
        return unless pin.is_a?(Pin::Block) && pin.receiver && !pin.rebound?
        # This first rebind just sets the block pin's rebound state
        pin.rebind ComplexType::UNDEFINED
        chain = Solargraph::Source::NodeChainer.chain(pin.receiver, pin.location.filename)
        return if skippable_block_receivers(api_map).include?(chain.links.last.word)
        if ['instance_eval', 'instance_exec', 'class_eval', 'class_exec', 'module_eval', 'module_exec'].include?(chain.links.last.word)
          type = chain.base.infer(api_map, pin, locals)
          pin.rebind type
        else
          receiver_pin = chain.define(api_map, pin, locals).first
          return if receiver_pin.nil? || receiver_pin.docstring.nil?
          ys = receiver_pin.docstring.tag(:yieldself)
          unless ys.nil? || ys.types.nil? || ys.types.empty?
            ysct = ComplexType.try_parse(*ys.types).qualify(api_map, receiver_pin.context.namespace)
            pin.rebind ysct
          end
        end
      end
    end
  end
end
