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
        dirs = metagem.require_paths +
               Convention.extra_source_paths(root: metagem.full_path, require_paths: metagem.require_paths)
        files = dirs.flat_map { |path| Dir.glob(File.join(metagem.full_path, path, '**', '*.rb')) }.uniq
        source_maps = files.map { |file| Solargraph::SourceMap.load(file) }

        # Generating an ApiMap is necessary for processing macros
        bench = Bench.new(source_maps: source_maps)
        source_pins = ApiMap.new.catalog(bench).pins.select { |pin| files.include?(pin.filename) }

        rbs_pins = RbsMap::Gem.pins(metagem)
        RbsMap::Helpers.combine(source_pins, rbs_pins)
      end
    end
  end
end
