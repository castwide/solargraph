# frozen_string_literal: true

module Solargraph
  module Typedef
    # Temporary utilities for using typedef in chain inference.
    class Dictionary
      include Linker
      include Helpers

      attr_reader :api_map

      attr_reader :source_map

      attr_reader :position

      # @param api_map [ApiMap]
      # @param source_map [SourceMap, String] A SourceMap object or filename
      # @param position [Position, Array(Integer, Integer)]
      def initialize api_map, source_map, position, chain: nil
        @api_map = api_map
        @source_map = source_map.is_a?(SourceMap) ? source_map : api_map.source_map(source_map)
        @position = Solargraph::Position.normalize(position)
        @chain = chain
      end

      def chain
        @chain ||= Solargraph::Source::SourceChainer.chain(source_map.source, position)
      end

      def closure
        @closure ||= source_map.locate_closure_pin(position.line, position.character)
      end

      def location
        @location ||= Location.new(source_map.filename, Range.new(position, position))
      end

      def locals
        @locals ||= source_map.locals_at(location)
      end

      # @return [Array<Pin::Base>]
      def define
        pins, _ = define_from chain
        pins
      end

      # @return [Array<Typedef::Type>]
      def infer
        pins, receiver = define_from chain
        proxies = infer_proxies(pins, receiver)
        proxies.flat_map(&:typedef_return_types)
      end

      # @param [Source::Chain]
      # @return [Array(Array<Pin::Base>, Pin::Closure)]
      def define_from chain
        return [[closure], closure.closure] if chain.undefined?

        pins = []
        current_closure = closure
        last_link = chain.links.last
        chain.links.each do |link|
          last_closure = current_closure
          pins = hitch(link, current_closure)
          pins = infer_proxies(pins, last_closure) if link != last_link
          return [[], nil] unless pins&.any?
          current_closure = if link == last_link
            current_closure
          else
            closure_from(pins)
          end
          return [[], nil] unless current_closure
        end
        [pins, current_closure]
      end

      def closure_from pins
        pins.find { |pin| pin.typedef_return_types.first.resolve_rooted(api_map, pin.closure.gates) }
      end

      # @param pins [Array<Pin::Base>]
      # @param receiver [Pin::Closure]
      # @return [Array<Pin::ProxyType>]
      def infer_proxies pins, receiver
        pins.flat_map { |pin| pin.is_a?(Pin::Method) ? find_matching_signature(pin) : pin }
            .flat_map do |pin|
          expand_tokens(pin, receiver).map { |type| root_and_infer(pin, type, receiver) }
                                      .map { |type| Pin::ProxyType.anonymous(type.to_complex_type, closure: pin.closure) }
        end
      end

      # @param pin [Pin::Base]
      # @param type [Typedef::Type]
      # @param receiver [Pin::Closure]
      # @return [Typedef::Type]
      def root_and_infer pin, type, receiver
        rooted = type.resolve_rooted(api_map, receiver.closure&.gates || [''])
        if rooted.base.to_s == 'undefined'
          pin.infer(api_map).to_typedef_types.first # @todo Better way without #first?
        else
          type
        end
      end

      # @todo Either implement this or (more likely) handle it in Linker::Call
      # @param pin [Pin::Method]
      # @return [Pin::Signature, Pin::Method]
      def find_matching_signature(pin)
        pin.signatures.find do |sig|
          # puts "Check against #{chain.inspect}"
          false
        end || pin
      end
    end
  end
end
