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

    # @param pins [Array<Pin::Base>]
    # @return [Array<Pin::Base>]
    def self.combine_method_pins_by_path(pins)
      method_pins, alias_pins = pins.partition { |pin| pin.class == Pin::Method }
      by_path = method_pins.group_by(&:path)
      by_path.transform_values! do |pins|
        GemPins.combine_method_pins(*pins)
      end
      by_path.values + alias_pins
    end

    # @param pins [Array<Pin::Method>]
    # @return [Pin::Method, nil]
    def self.combine_method_pins(*pins)
      # @type [Pin::Method, nil]
      combined_pin = nil
      # @param memo [Pin::Method, nil]
      # @param pin [Pin::Method]
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
      logger.debug { "GemPins.combine_method_pins(pins.length=#{pins.length}, pins=#{pins}) => #{out.inspect}" }
      out
    end

    # @param yard_plugins [Array<String>] The names of YARD plugins to use.
    # @param gemspec [Gem::Specification]
    # @return [Array<Pin::Base>]
    def self.build_yard_pins(yard_plugins, gemspec)
      Yardoc.cache(yard_plugins, gemspec) unless Yardoc.cached?(gemspec)
      yardoc = Yardoc.load!(gemspec)
      YardMap::Mapper.new(yardoc, gemspec).map
    end

    # @param yard_pins [Array<Pin::Base>]
    # @param rbs_pins [Array<Pin::Base>]
    #
    # @return [Array<Pin::Base>]
    def self.combine(yard_pins, rbs_pins)
      in_yard = Set.new
      rbs_api_map = Solargraph::ApiMap.new(pins: rbs_pins)
      combined = yard_pins.map do |yard_pin|
        in_yard.add yard_pin.path
        rbs_pin = rbs_api_map.get_path_pins(yard_pin.path).filter { |pin| pin.is_a? Pin::Method }.first
        next yard_pin unless rbs_pin && yard_pin.class == Pin::Method

        unless rbs_pin
          # @sg-ignore https://github.com/castwide/solargraph/pull/1114
          logger.debug { "GemPins.combine: No rbs pin for #{yard_pin.path} - using YARD's '#{yard_pin.inspect} (return_type=#{yard_pin.return_type}; signatures=#{yard_pin.signatures})" }
          next yard_pin
        end

        out = combine_method_pins(rbs_pin, yard_pin)
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
        choices.find { |pin| pin.defined? } || choices.first || ComplexType::UNDEFINED
      end
    end
  end
end
