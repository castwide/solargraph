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
      autoload :Variable,         'solargraph/source/chain/variable'
      autoload :ClassVariable,    'solargraph/source/chain/class_variable'
      autoload :Constant,         'solargraph/source/chain/constant'
      autoload :InstanceVariable, 'solargraph/source/chain/instance_variable'
      autoload :GlobalVariable,   'solargraph/source/chain/global_variable'
      autoload :Literal,          'solargraph/source/chain/literal'
      autoload :Head,             'solargraph/source/chain/head'
      autoload :Or,               'solargraph/source/chain/or'
      autoload :BlockVariable,    'solargraph/source/chain/block_variable'

      @@inference_stack = []
      @@inference_depth = 0
      @@last_api_map = nil
      @@pin_cache = {}

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
          # @todo There's a problem here. Call links need to resolve arguments
          #   that might refer to local variables.
          # locals = []
          type = infer_first_defined(pins, working_pin, api_map)
          return [] if type.undefined?
          working_pin = Pin::ProxyType.anonymous(type)
        end
        links.last.last_context = working_pin
        links.last.resolve(api_map, working_pin, locals)
      end

      # @param api_map [ApiMap]
      # @param name_pin [Pin::Base]
      # @param locals [Array<Pin::Base>]
      # @return [ComplexType]
      def infer api_map, name_pin, locals
        rebind_block name_pin, api_map, locals
        pins = define(api_map, name_pin, locals)
        infer_first_defined(pins, links.last.last_context, api_map)
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

      private

      # @param pins [Array<Pin::Base>]
      # @param api_map [ApiMap]
      # @return [ComplexType]
      def infer_first_defined pins, context, api_map
        type = ComplexType::UNDEFINED
        pins.each do |pin|
          type = pin.typify(api_map)
          break if type.defined?
        end
        if type.undefined?
          # Limit method inference recursion
          return type if @@inference_depth >= 2 && pins.first.is_a?(Pin::BaseMethod)
          @@inference_depth += 1
          name_count = {}
          pins.each do |pin|
            # Limit pin name hits for, e.g., variables with insane amounts of definitions
            name_count[pin.identity] ||= 0
            name_count[pin.identity] += 1
            next if name_count[pin.identity] >= 10
            # Avoid infinite recursion
            next if @@inference_stack.include?(pin)
            @@inference_stack.push pin
            # puts "    Inferring #{pin.class} | #{pin.path} | #{pin.name} | #{pin.location ? pin.location.to_hash : pin.location}"
            # type = pin.probe(api_map)
            type = remember_or_probe(pin, api_map)
            @@inference_stack.pop
            break if type.defined?
          end
          @@inference_depth -= 1
        end
        return type if context.nil? || context.return_type.undefined?
        type.self_to(context.return_type.namespace)
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

      def remember_or_probe pin, api_map
        @@pin_cache.clear if @@last_api_map != api_map
        @@last_api_map = api_map
        @@pin_cache[pin] ||= pin.probe(api_map)
      end
    end
  end
end
