# frozen_string_literal: true

module Solargraph
  module Typedef
    # Temporary utilities for using typedef in chain inference.
    module Inference
      module_function

      # @param chain [Solargraph::Source::Chain]
      # @param api_map [Solargraph::Source::ApiMap]
      # @param location [Solargraph::Location]
      def define_from_chain chain, api_map, location
        closure = api_map.source_map(location.filename).locate_closure_pin(location.range.start.line, location.range.start.character)
        pins = []
        chain.links.each do |link|
          # @todo next closure
          pins = define_from_link(link, api_map, closure)
          return [] if pins.empty?
          closure = closure_from(pins, api_map)
          return [] unless closure
        end
        pins
      end

      # @param link [Solargraph::Source::Chain::Link]
      # @param api_map [Solargraph::Source::ApiMap]
      def define_from_link link, api_map, closure
        case link
        when Solargraph::Source::Chain::Call
          # @todo Is checking the first return type enough?
          api_map.typedef_path_methods(closure.typedef_path)
                  .select { |pin| pin.name == link.word }
        end
      end

      def closure_from pins, api_map
        pins.each do |pin|
          # @todo Is checking the first return type enough?
          found = pins.find { |pin| pin.typedef_return_types.first.resolve_rooted(api_map, pin.closure.gates).resolved? }
          resolved = found.typedef_return_types.first.resolve_rooted(api_map, pin.closure.gates)
          return resolved if resolved.resolved?
        end
        nil
      end
    end
  end
end
