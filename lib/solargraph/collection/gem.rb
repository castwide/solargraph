# frozen_string_literal: true

module Solargraph
  module Collection
    # Cacheable gem pins.
    #
    class Gem < Base
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
        GemPins.combine(yard_pins, rbs_pins)
      end

      def uncacheable_pins
        files = metagem.require_paths.flat_map { |path| Dir.glob(File.join(metagem.full_path, path, '**', '*.rb')) }
        source_maps = files.map { |file| Solargraph::SourceMap.load(file) }
        source_pins = source_maps.flat_map(&:pins)
        rbs_pins = RbsMap::Gem.pins(metagem)
        GemPins.combine(source_pins, rbs_pins)
      end
    end
  end
end
