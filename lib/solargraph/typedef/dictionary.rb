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

      # @return [Pin::Closure, nil]
      def closure
        @closure ||= position ? source_map.locate_closure_pin(position.line, position.character) : nil
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
              .map { |pin| pin.proxy(pin.typedef_typeset.resolve_rooted(api_map, pin.gates).to_complex_type) }
        end
      end

      # Get the first declared return type without inference.
      #
      # @return [Typeset]
      def declare
        # rubocop:disable-next Lint/UselessDefaultValueArgument
        Typedef.memos.fetch memo_key(:declare), Typeset::UNDEFINED do
          typify infer: false
        end
      end

      # Get the first declared return type or infer the type from code.
      #
      # @return [Typeset]
      def infer
        # rubocop:disable-next Lint/UselessDefaultValueArgument
        Typedef.memos.fetch memo_key(:infer), Typeset::UNDEFINED do
          typify infer: true
        end
      end

      # @param api_map [ApiMap]
      # @param source_map [SourceMap, String] A SourceMap object or filename
      # @param position [Position, Array(Integer, Integer), nil]
      def self.at api_map, source_map, position
        source_map = api_map.source_map(source_map) unless source_map.is_a?(SourceMap)
        position = Position.normalize(position)
        tree = source_map.source.tree_at(position.line, position.column)
        chain = Solargraph::Parser.chain(tree[0], source_map.filename, tree[1], tree)
        new(api_map, source_map, chain)
      end

      private

      def typify infer: true
        pins, receiver = define_from_chain
        return ComplexType::UNDEFINED.to_typedef_typeset if pins.empty?

        Filter.new(api_map, pins, receiver, infer: infer)
              .typeset
              .resolve_rooted(api_map, receiver.gates)
      end

      # @param chain [Source::Chain]
      # @return [Array<Pin::Base>, Pin::Closure)]
      def define_from_chain
        return [[], nil] if closure.nil? && chain.undefined?
        return [[closure], closure.closure] if chain.undefined?

        pins = []
        receiver = closure
        last_index = chain.links.length - 1
        chain.links.each_with_index do |link, index|
          pins = hitch(link, receiver)
          break if index == last_index

          proxy = Filter.new(api_map, pins, receiver).proxy
          return [[], receiver] if proxy.typedef_typeset.undefined?
          receiver = proxy
        end
        [pins, receiver]
      end

      # @param action [Symbol]
      # @return [Memoizer::Key]
      def memo_key action
        Memoizer::Key.new(api_map, source_map.filename, { chain: chain, closure: closure, action: action })
      end
    end
  end
end
