# frozen_string_literal: true

module Solargraph
  module Typedef
    # Type expansion and resolution utilities.
    #
    class Dictionary
      include Linker

      # @return [ApiMap]
      attr_reader :api_map

      # @return [SourceMap]
      attr_reader :source_map

      # @return [Chain]
      attr_reader :chain

      # @param api_map [ApiMap]
      # @param source_map [SourceMap, String] A SourceMap object or filename
      # @param chain [Source::Chain]
      # @param closure [Pin::Closure, nil]
      def initialize api_map, source_map, chain, closure: nil
        @api_map = api_map
        @source_map = source_map.is_a?(SourceMap) ? source_map : api_map.source_map(source_map)
        @position = Solargraph::Position.normalize(position) if position
        @chain = chain
        @closure = closure
      end

      def position
        @position ||= Range.from_node(chain&.node)&.ending
      end

      # @return [Pin::Closure]
      def closure
        @closure ||= source_map.locate_closure_pin(position.line, position.character)
      end

      # @return [Location]
      def location
        @location ||= Location.new(source_map.filename, Range.new(position, position))
      end

      # @return [Array<Pin::BaseVariable>]
      def locals
        @locals ||= source_map.locals_at(location)
      end

      # @return [Array<Pin::Base>]
      def define
        # rubocop:disable-next Lint/UselessDefaultValueArgument
        Typedef.memos.fetch memo_key(:define), [] do
          pins, receiver = define_from_chain
          pins.map { |pin| pin.proxy(Expansions::Macros.expand(api_map, pin, receiver).to_complex_type) }
        end
      end

      # @return [Typeset]
      def infer
        # rubocop:disable-next Lint/UselessDefaultValueArgument
        Typedef.memos.fetch memo_key(:infer), Typeset::UNDEFINED do
          pins, receiver = define_from_chain
          return ComplexType::UNDEFINED.to_typedef_typeset if pins.empty?

          Filter.new(api_map, pins, receiver).typeset
        end
      end

      # @param api_map [ApiMap]
      # @param source_map [SourceMap, String] A SourceMap object or filename
      # @param position [Position, Array(Integer, Integer), nil]
      def self.at(api_map, source_map, position)
        source_map = source_map.is_a?(SourceMap) ? source_map : api_map.source_map(source_map)
        chain = Solargraph::Source::SourceChainer.chain(source_map.source, position)
        new(api_map, source_map, chain)
      end

      private

      # @param chain [Source::Chain]
      # @return [Array<Pin::Base>, Pin::Closure)]
      def define_from_chain
        return [[closure], closure.closure] if chain.undefined?
          pins = []
          receiver = closure
          last_link = chain.links.last
          chain.links.each do |link|
            pins = hitch(link, receiver)
            break if link == last_link

            proxy = Filter.new(api_map, pins, receiver).proxy
            return [[], receiver] if proxy.typedef_typeset.undefined?
            receiver = proxy
          end
          [pins, receiver]
      end

      # @param action [Symbol]
      # @return [Key]
      def memo_key action
        Memoizer::Key.new(filename: source_map.filename, api_map: api_map, chain: chain, closure: closure, action: action)
      end
    end
  end
end
