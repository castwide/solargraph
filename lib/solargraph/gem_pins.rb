# frozen_string_literal: true

require 'rbs'

module Solargraph
  # A utility for building gem pins from a combination of YARD and RBS
  # documentation.
  #
  module GemPins
    # Build an array of pins from a gem specification. The process starts with
    # YARD, enhances the resulting pins with RBS definitions, and appends RBS
    # pins that don't exist in the YARD mapping.
    #
    # @param gemspec [Gem::Specification]
    # @return [Array<Pin::Base>]
    def self.build(gemspec)
      yard_pins = build_yard_pins(gemspec)
      rbs_map = RbsMap.from_gemspec(gemspec)
      in_yard = Set.new
      combined = yard_pins.map do |yard|
        in_yard.add yard.path
        next yard unless yard.is_a?(Pin::Method)
        rbs = rbs_map.path_pin(yard.path)
        next yard unless rbs
        # @todo Could not include: attribute and anon_splat
        # @sg-ignore
        yard.class.new(
          location: yard.location,
          closure: yard.closure,
          name: yard.name,
          comments: yard.comments,
          scope: yard.scope,
          parameters: rbs.parameters,
          generics: rbs.generics,
          node: yard.node,
          signatures: yard.signatures,
          return_type: best_return_type(rbs.return_type, yard.return_type)
        )
      end
      in_rbs = rbs_map.pins.reject { |pin| in_yard.include?(pin.path) }
      combined + in_rbs
    end

    class << self
      private

      # @param gemspec [Gem::Specification]
      # @return [Array<Pin::Base>]
      def build_yard_pins(gemspec)
        Yardoc.cache(gemspec) unless Yardoc.cached?(gemspec)
        yardoc = Yardoc.load!(gemspec)
        YardMap::Mapper.new(yardoc, gemspec).map
      end

      # Select the first defined type.
      #
      # @param choices [Array<ComplexType>]
      # @return [ComplexType]
      def best_return_type *choices
        choices.find { |pin| pin.defined? } || choices.first || ComplexType::UNDEFINED
      end
    end
  end
end
