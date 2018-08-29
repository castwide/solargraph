# HACK Fix autoload issue
require 'solargraph/source/chain/link'

module Solargraph
  class Source
    class Chain
      autoload :Link,             'solargraph/source/chain/link'
      autoload :Call,             'solargraph/source/chain/call'
      autoload :Variable,         'solargraph/source/chain/variable'
      autoload :ClassVariable,    'solargraph/source/chain/class_variable'
      autoload :Constant,         'solargraph/source/chain/constant'
      autoload :InstanceVariable, 'solargraph/source/chain/instance_variable'
      autoload :GlobalVariable,   'solargraph/source/chain/global_variable'
      autoload :Literal,          'solargraph/source/chain/literal'
      autoload :Definition,       'solargraph/source/chain/definition'

      UNDEFINED_CALL = Source::Chain::Call.new('<undefined>')
      UNDEFINED_CONSTANT = Source::Chain::Constant.new('<undefined>')

      # @return [Array<Source::Chain::Link>]
      attr_reader :links

      # @param filename [String]
      # @param links [Array<Chain::Link>]
      def initialize filename, links
        @filename = filename
        @links = links
        @links.push UNDEFINED_CALL if @links.empty?
      end

      # @return [Array<Source::Chain::Link>]
      def base
        # @todo It might make sense for the chain links to always have a root.
        @base ||= links[0..-2]
      end

      # @return [Source::Chain::Link]
      def tail
        @tail ||= links.last
      end

      def literal?
        tail.is_a?(Literal)
      end

      # @param api_map [ApiMap]
      # @param context [Pin::Base]
      # @param locals [Array<Pin::Base>]
      # @return [Array<Pin::Base>]
      def define_with api_map, context, locals
        inner_define_with links, api_map, context, locals
      end

      def define_base_with api_map, context, locals
        inner_define_with links[0..-2], api_map, context, locals
      end

      # @param api_map [ApiMap]
      # @param context [Pin::Base]
      # @param locals [Array<Pin::Base>]
      # @return [ComplexType]
      def infer_type_with api_map, context, locals
        # @todo Perform link inference
        inner_infer_type_with(links, api_map, context, locals)
      end

      def infer_base_type_with api_map, context, locals
        inner_infer_type_with(links[0..-2], api_map, context, locals)
      end

      private

      def inner_infer_type_with array, api_map, context, locals
        type = ComplexType::UNDEFINED
        pins = inner_define_with(array, api_map, context, locals)
        pins.each do |pin|
          type = pin.infer(api_map)
          break unless type.undefined?
        end
        type
      end

      def inner_define_with array, api_map, context, locals
        return [] if array.empty?
        type = ComplexType::UNDEFINED
        head = true
        # @param link [Chain::Link]
        array[0..-2].each do |link|
          pins = link.resolve_pins(api_map, context, head ? locals : [])
          head = false
          return [] if pins.empty?
          pins.each do |pin|
            type = pin.infer(api_map)
            break unless type.undefined?
          end
          return [] if type.undefined?
          context = Pin::ProxyType.anonymous(type)
        end
        array.last.resolve_pins(api_map, context, head ? locals: [])
      end
    end
  end
end
