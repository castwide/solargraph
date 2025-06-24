# frozen_string_literal: true

require 'rbs'

module Solargraph
  # A utility for building gem pins from a combination of YARD and RBS
  # documentation.
  #
  module GemPins
    class << self
      include Logging
    end

    def log_level
      :debug
    end

    # @param gemspec [Gem::Specification]
    # @return [Array<Pin::Base>]
    def self.build_yard_pins(gemspec)
      Yardoc.cache(gemspec) unless Yardoc.cached?(gemspec)
      yardoc = Yardoc.load!(gemspec)
      YardMap::Mapper.new(yardoc, gemspec).map
    end

    # Build an array of pins by combining YARD and RBS
    # information.
    #
    # @param yard_pins [Array<Pin::Base>]
    # @param rbs_map [RbsMap]
    # @return [Array<Pin::Base>]
    def self.combine(yard_pins, rbs_pins)
      in_yard = Set.new
      rbs_api_map = Solargraph::ApiMap.new(pins: rbs_pins)
      combined = yard_pins.map do |yard|
        in_yard.add yard.path
        next yard unless yard.is_a?(Pin::Method)

        rbs = rbs_api_map.get_path_pins(yard.path).first
        next yard unless rbs && yard.is_a?(Pin::Method)

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
          return_type: best_return_type(rbs.return_type, yard.return_type),
          source: :gem_pins
        )
      end
      in_rbs = rbs_pins.reject { |pin| in_yard.include?(pin.path) }
      out = combined + in_rbs
      logger.debug { "GemPins#combine: Returning #{out.length} combined pins" }
      out
    end

    class << self
      private

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
