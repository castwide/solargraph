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

    # Build an array of pins from a gem specification. The process starts with
    # YARD, enhances the resulting pins with RBS definitions, and appends RBS
    # pins that don't exist in the YARD mapping.
    #
    # @param gemspec [Gem::Specification]
    # @return [Array<Pin::Base>]
    def self.build(gemspec)
      yard_pins = build_yard_pins(gemspec)
      rbs_map = RbsMap.from_gemspec(gemspec)
      combine yard_pins, rbs_map
    end

    # @param pins [Array<Pin::Base>]
    def self.combine_method_pins_by_path(pins)
      # bad_pins = pins.select { |pin| pin.is_a?(Pin::Method) && pin.path == 'StringIO.open' && pin.source == :rbs }; raise "wtf: #{bad_pins}" if bad_pins.length > 1
      method_pins, alias_pins = pins.partition { |pin| pin.class == Pin::Method }
      by_path = method_pins.group_by(&:path)
      by_path.transform_values! do |pins|
        GemPins.combine_method_pins(*pins)
      end
      by_path.values + alias_pins
    end

    def self.combine_method_pins(*pins)
      out = pins.reduce(nil) do |memo, pin|
        next pin if memo.nil?
        if memo == pin && memo.source != :combined
          # @todo we should track down situations where we are handled
          #   the same pin from the same source here and eliminate them -
          #   this is an efficiency workaround for now
          next memo
        end
        memo.combine_with(pin)
      end
      logger.debug { "GemPins.combine_method_pins(pins.length=#{pins.length}, pins=#{pins}) => #{out.inspect}" }
      out
    end

    # @param yard_pins [Array<Pin::Base>]
    # @param rbs_map [RbsMap]
    # @return [Array<Pin::Base>]
    def self.combine(yard_pins, rbs_map)
      in_yard = Set.new
      rbs_api_map = Solargraph::ApiMap.new(pins: rbs_map.pins)
      combined = yard_pins.map do |yard_pin|
        next yard_pin unless yard_pin.class == Pin::Method

        in_yard.add yard_pin.path

        rbs_pin = rbs_api_map.get_path_pins(yard_pin.path).filter { |pin| pin.is_a? Pin::Method }.first
        unless rbs_pin
          logger.debug { "GemPins.combine: No rbs pin for #{yard_pin.path} - using YARD's '#{yard_pin.inspect} (return_type=#{yard_pin.return_type}; signatures=#{yard_pin.signatures})" }
          next yard_pin
        end

        out = combine_method_pins(rbs_pin, yard_pin)
        logger.debug { "GemPins.combine: Combining yard.path=#{yard_pin.path} - rbs=#{rbs_pin.inspect} with yard=#{yard_pin.inspect} into #{out}" }
        out
      end
      in_rbs_only = rbs_map.pins.select do |pin|
        pin.path.nil? || !in_yard.include?(pin.path)
      end
      combined + in_rbs_only
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
