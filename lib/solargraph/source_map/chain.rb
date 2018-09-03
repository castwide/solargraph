# HACK Fix autoload issue
require 'solargraph/source_map/chain/link'

module Solargraph
  class SourceMap
    class Chain
      autoload :Link,             'solargraph/source_map/chain/link'
      autoload :Call,             'solargraph/source_map/chain/call'
      autoload :Variable,         'solargraph/source_map/chain/variable'
      autoload :ClassVariable,    'solargraph/source_map/chain/class_variable'
      autoload :Constant,         'solargraph/source_map/chain/constant'
      autoload :InstanceVariable, 'solargraph/source_map/chain/instance_variable'
      autoload :GlobalVariable,   'solargraph/source_map/chain/global_variable'
      autoload :Literal,          'solargraph/source_map/chain/literal'
      autoload :Definition,       'solargraph/source_map/chain/definition'
      autoload :Head,             'solargraph/source_map/chain/head'

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
      # @param context [Context]
      # @param locals [Array<Pin::Base>]
      # @return [Array<Pin::Base>]
      def define api_map, context, locals
        return [] if undefined?
        type = ComplexType::UNDEFINED
        head = true
        links[0..-2].each do |link|
          pins = link.resolve(api_map, context, head ? locals : [])
          head = false
          return [] if pins.empty?
          pins.each do |pin|
            type = pin.infer(api_map)
            break unless type.undefined?
          end
          return [] if type.undefined?
          context = type
        end
        links.last.resolve(api_map, context, head ? locals: [])
      end

      # @param api_map [ApiMap]
      # @param api_map [Context]
      # @param locals [Array<Pin::Base>]
      # @return [ComplexType]
      def infer api_map, context, locals
        return ComplexType::UNDEFINED if undefined?
        type = ComplexType::UNDEFINED
        pins = define(api_map, context, locals)
        pins.each do |pin|
          type = pin.infer(api_map)
          break unless type.undefined?
        end
        type
      end

      def literal?
        links.last.is_a?(Chain::Literal)
      end

      def undefined?
        links.any?(&:undefined?)
      end

      def constant?
        links.last.is_a?(Chain::Constant)
      end
    end
  end
end
