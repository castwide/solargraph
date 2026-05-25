# frozen_string_literal: true

module Solargraph
  module Typedef
    # Temporary utilities for using typedef in chain inference.
    class Dictionary
      include Linker

      attr_reader :api_map

      attr_reader :source_map

      attr_reader :position

      # @param api_map [ApiMap]
      # @param source_map [SourceMap, String] A SourceMap object or filename
      # @param position [Position, Array(Integer, Integer)]
      def initialize api_map, source_map, position
        @api_map = api_map
        @source_map = source_map.is_a?(SourceMap) ? source_map : api_map.source_map(source_map)
        @position = Solargraph::Position.normalize(position)
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

      protected

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
        named_values = if receiver
          pins.reduce({}) do |hash, pin|
            hash.merge (
              pin.closure
                .generics
                .map { |name| "generic<#{name}>" }
                .zip(receiver.typedef_return_types.first.params.map { |type| type.resolve_rooted(api_map, [receiver.path]) })
                .to_h
            )            
          end
        else
          {}
        end
        named_values['self'] = receiver&.namespace
        pins.map(&:typedef_return_types)
            .map { |array| array.map { |type| type.resolve_named_tokens(named_values) } }
            .map do |array|
              array.map.with_index do |type, idx|
                type = type.resolve_rooted(api_map, receiver.closure&.gates || [''])
                if type.base.to_s == 'undefined'
                  pins[idx].infer(api_map).to_typedef_types.first # @todo Better way?
                else
                  type
                end
              end
            end
            .map { |types| Pin::ProxyType.anonymous(ComplexType.new(types.map(&:to_complex_type))) }
      end
    end
  end
end
