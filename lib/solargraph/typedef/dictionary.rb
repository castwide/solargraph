# frozen_string_literal: true

module Solargraph
  module Typedef
    # Temporary utilities for using typedef in chain inference.
    class Dictionary
      attr_reader :api_map

      attr_reader :location

      # @param api_map [ApiMap]
      # @param location [Location]
      def initialize api_map, location
        @api_map = api_map
        @location = location
      end

      def source_map
        @source_map ||= api_map.source_map(location.filename)
      end

      def chain
        @chain ||= Solargraph::Source::SourceChainer.chain(source_map.source, location.range.start)
      end

      def closure
        @closure ||= api_map.source_map(location.filename).locate_closure_pin(location.range.start.line, location.range.start.character)
      end

      # @return [Array<Pin::Base>]
      def define
        current_closure = closure
        pins = []
        chain.links.each do |link|
          pins = resolve_link(link, current_closure)
          return [] unless pins&.any?
          current_closure = closure_from(pins)
          return [] unless current_closure
        end
        pins
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
          pins = resolve_link(link, current_closure)
          return [] unless pins&.any?
          current_closure = closure_from(pins)
          return [] unless current_closure
        end
        pins
      end

      # @param link [Solargraph::Source::Chain::Link]
      # @param api_map [Solargraph::Source::ApiMap]
      # @param closure [Solargraph::Pin::Closure]
      # @return [Array<Pin::Base>]
      def resolve_link link, closure
        case link
        when Solargraph::Source::Chain::Head
          return [Pin::ProxyType.anonymous(closure.binder, source: :chain)] if link.word == 'self'
          []
        when Solargraph::Source::Chain::Call
          closure.typedef_return_types
                 .map { |type| type.resolve_rooted(api_map, [closure.namespace]) }
                 .flat_map { |type| api_map.typedef_path_methods(type.base) }
                 .select { |pin| pin.name == link.word }
        else
          raise "#{link.class} not implemented"
        end
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
