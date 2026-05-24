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
      # @param source_map [SourceMap, String]
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

      # @return [Array<Pin::Base>]
      def define
        define_from chain
      end

      # @return [Array<Typedef::Type>]
      def infer
        pins = define
        # @todo Limit to first?
        receiver = define_from(chain.base).first
        # pins.flat_map do |pin|
        pin = pins.first
          named_values = pin.closure.generics
                            .map { |name| "generic<#{name}>" }
                            .zip(receiver.typedef_return_types.first.params.map { |type| type.resolve_rooted(api_map, [receiver.path]) })
                            .to_h
          pin.typedef_return_types
             .map { |type| type.resolve_named_tokens(named_values).resolve_rooted(api_map, [type.base.name]) }
        # end
      end

      private

      def define_from chain
        pins = []
        current_closure = closure
        chain.links.each do |link|
          pins = hitch(link, current_closure)
          return [] unless pins&.any?
          current_closure = closure_from(pins)
          return [] unless current_closure
        end
        pins
      end

      def closure_from pins
        pins.each do |pin|
          # @todo Is checking the first return type enough?
          found = pins.find { |pin| pin.typedef_return_types.first.resolve_rooted(api_map, pin.closure.gates).resolved? }
          return found if found
        end
        nil
      end
    end
  end
end
