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

    # Pin types whose YARD/RBS pins should merge via #combine_with
    # instead of one side simply winning.
    COMBINABLE_PIN_TYPES = [Pin::Method, Pin::Namespace].freeze

    # @param pins [Array<Pin::Base>]
    # @return [Pin::Base, nil]
    def self.combine_pins(*pins)
      # @type [Pin::Base, nil]
      combined_pin = nil
      # @param memo [Pin::Base, nil]
      # @param pin [Pin::Base]
      out = pins.reduce(combined_pin) do |memo, pin|
        next pin if memo.nil?
        if memo == pin && memo.source != :combined
          # @todo we should track down situations where we are handled
          #   the same pin from the same source here and eliminate them -
          #   this is an efficiency workaround for now
          next memo
        end
        memo.combine_with(pin)
      end
      logger.debug { "GemPins.combine_pins(pins.length=#{pins.length}, pins=#{pins}) => #{out.inspect}" }
      out
    end

    # @param yard_plugins [Array<String>] The names of YARD plugins to use.
    # @param gemspec [Gem::Specification]
    # @return [Array<Pin::Base>]
    def self.build_yard_pins yard_plugins, gemspec
      Yardoc.cache(yard_plugins, gemspec) unless Yardoc.cached?(gemspec)
      return [] unless Yardoc.cached?(gemspec)
      yardoc = Yardoc.load!(gemspec)
      YardMap::Mapper.new(yardoc, gemspec).map
    end

    # @param yard_pins [Array<Pin::Base>]
    # @param rbs_pins [Array<Pin::Base>]
    #
    # @return [Array<Pin::Base>]
    def self.combine yard_pins, rbs_pins
      in_yard = Set.new
      rbs_api_map = Solargraph::ApiMap.new(pins: rbs_pins)
      combined = yard_pins.map do |yard_pin|
        in_yard.add yard_pin.path
        next yard_pin unless COMBINABLE_PIN_TYPES.any? { |type| yard_pin.instance_of?(type) }

        rbs_pin = rbs_api_map.get_path_pins(yard_pin.path).find { |pin| pin.instance_of?(yard_pin.class) }
        unless rbs_pin
          logger.debug { "GemPins.combine: No rbs pin for #{yard_pin.path} - using YARD's '#{yard_pin.inspect}" }
          next yard_pin
        end

        out = combine_pins(rbs_pin, yard_pin)
        logger.debug { "GemPins.combine: Combining yard.path=#{yard_pin.path} - rbs=#{rbs_pin.inspect} with yard=#{yard_pin.inspect} into #{out}" }
        out
      end
      in_rbs_only = rbs_pins.select do |pin|
        pin.path.nil? || !in_yard.include?(pin.path)
      end
      out = combined + in_rbs_only
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
        choices.find(&:defined?) || choices.first || ComplexType::UNDEFINED
      end
    end
  end
end
