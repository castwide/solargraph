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

          infer_typeset(pins, receiver)
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

            proxy = infer_proxy(pins, receiver)
            return [[], receiver] if proxy.to_s == 'undefined' # @todo Better way to identify undefined
            receiver = proxy
          end
          [pins, receiver]
      end

      def infer_typeset pins, receiver
        expanded = if receiver
                     pins.map { |pin| pin.proxy(Expansions::Generics.expand(api_map, pin, receiver).to_complex_type) }
                         .map { |pin| pin.proxy(expand_root(pin, receiver).to_complex_type) }
                         .map { |pin| expand_self(pin, receiver) }
                   else
                     pins
                   end

        case expanded.first
        when Pin::BaseVariable
          first_declared_or_combined expanded, receiver
        when Pin::Method, Pin::Signature
          first_declared_or_inferred expanded, receiver
        when Pin::ProxyType
          expanded.first.typedef_typeset
        else
          # @todo Check for additional cases
          first_declared_or_inferred expanded, receiver
        end
      end

      # @param pins [Array<Pin::Base>]
      # @param receiver [Pin::Closure]
      # @return [Pin::ProxyType]
      def infer_proxy pins, receiver
        inferred = infer_typeset(pins, receiver)
        Pin::ProxyType.anonymous(inferred.to_complex_type)
      end

      # @return [Typeset]
      def first_declared_or_combined pins, receiver
        declared = pins.find { |pin| pin.typedef_typeset.to_s != 'undefined' } # @todo Better way to identify undefined
        return declared.typedef_typeset if declared

        inferred = pins.filter_map do |pin|
          inferred = Expansions::Inference.expand(api_map, pin, receiver)
          return inferred if inferred.to_s == 'undefined' # @todo Better way to identify undefined
          inferred
        end

        Typeset.new(inferred)
      end

      # @return [Typeset]
      def first_declared_or_inferred pins, receiver
        declared = pins.find { |pin| pin.typedef_typeset.to_s != 'undefined' } # @todo Better way to identify undefined
        return declared.typedef_typeset if declared

        pins.each do |pin|
          inferred = Expansions::Inference.expand(api_map, pin, receiver)
          return inferred unless inferred.to_s == 'undefined' # @todo Better way to identify undefined
        end

        ComplexType::UNDEFINED.to_typedef_typeset
      end

      # @param pin [Pin::Base]
      # @param receiver [Pin::Closure, Pin::ProxyType]
      # @return [Typeset]
      def expand_root pin, receiver
        pin.typedef_typeset.resolve_rooted(api_map, receiver&.closure&.gates || [''])
      end

      def expand_self pin, receiver
        # @todo A Class#new exception is necessary because the current pin from
        #   RBS core has return type `undefined`. A better solution is a
        #   CoreFills override of `Class#new => self`, but it interferes with
        #   the existing chain inference.
        if pin.path == 'Class#new'
          pin.proxy(Solargraph::ComplexType.parse('::Class'))
        else
          pin.proxy(pin.typedef_typeset.expand({ 'self' => receiver.typedef_typeset }).to_complex_type)
        end
      end

      # @param action [Symbol]
      # @return [Key]
      def memo_key action
        Memoizer::Key.new(filename: source_map.filename, api_map: api_map, chain: chain, closure: closure, action: action)
      end
    end
  end
end
