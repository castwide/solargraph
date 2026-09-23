# frozen_string_literal: true

module Solargraph
  module Collection
    # Cacheable gem pins.
    #
    class Gem < Base
      include Logging

      attr_reader :metagem

      # @param metagem [Metagem]
      def initialize metagem
        @metagem = metagem
      end

      def cache_file
        File.join CacheDir.work_dir, 'gems', "#{metagem.cache_name}.ser"
      end

      def load
        return pins unless metagem.cacheable?
        super
      end

      def pins
        @pins ||= if metagem.cacheable?
          cacheable_pins
        else
          uncacheable_pins
        end
      end

      def self.cached? metagem
        metagem.cacheable? && File.exist?(new(metagem).cache_file)
      end

      private

      def cacheable_pins
        code_objects = Yardoc.load!(metagem)
        yard_pins = YardMap::Mapper.new(code_objects, metagem).map
        rbs_pins = RbsMap::Gem.pins(metagem)
        combine(yard_pins, rbs_pins)
      end

      def uncacheable_pins
        files = metagem.require_paths.flat_map { |path| Dir.glob(File.join(metagem.full_path, path, '**', '*.rb')) }
        source_maps = files.map { |file| Solargraph::SourceMap.load(file) }
        source_pins = source_maps.flat_map(&:pins)
        rbs_pins = RbsMap::Gem.pins(metagem)
        combine(source_pins, rbs_pins)
      end

      # @param yard_pins [Array<Pin::Base>]
      # @param rbs_pins [Array<Pin::Base>]
      #
      # @return [Array<Pin::Base>]
      def combine yard_pins, rbs_pins
        in_yard = Set.new
        # @todo There's gotta be a better way!
        rbs_api_map = Solargraph::ApiMap.new(pins: rbs_pins)
        combined = yard_pins.map do |yard_pin|
          in_yard.add yard_pin.path
          rbs_pin = rbs_api_map.get_path_pins(yard_pin.path).filter { |pin| pin.is_a? Pin::Method }.first
          next yard_pin unless rbs_pin && yard_pin.instance_of?(Pin::Method)

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

      # @param pins [Array<Pin::Method>]
      # @return [Pin::Method, nil]
      def combine_method_pins(*pins)
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
    end
  end
end
