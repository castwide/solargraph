# frozen_string_literal: true

module Solargraph
  module Collection
    # Cacheable gem pins.
    #
    class Gem < Base
      include Logging

      attr_reader :metagem

      @@path_source_cache = {}

      # @param metagem [Metagem]
      def initialize metagem
        super()
        @metagem = metagem
      end

      def cache_file
        File.join CacheDir.gem_dir, "#{metagem.cache_name}.ser"
      end

      def load
        return super if metagem.cacheable?
        @@path_source_cache[metagem.full_path] ||= pins
      end

      def pins
        @pins ||= without_yard
      end

      def self.cached? metagem
        metagem.cacheable? && File.exist?(new(metagem).cache_file)
      end

      private

      def with_yard
        code_objects = Yardoc.load!(metagem)
        yard_pins = YardMap::Mapper.new(code_objects, metagem).map
        rbs_pins = RbsMap::Gem.pins(metagem)
        RbsMap::Helpers.combine(yard_pins, rbs_pins)
      end

      def without_yard
        files = metagem.require_paths.flat_map { |path| Dir.glob(File.join(metagem.full_path, path, '**', '*.rb')) }
        source_maps = files.map { |file| Solargraph::SourceMap.load(file) }
        source_pins = source_maps.flat_map(&:pins)
        rbs_pins = RbsMap::Gem.pins(metagem)
        RbsMap::Helpers.combine(source_pins, rbs_pins)
      end
    end
  end
end
