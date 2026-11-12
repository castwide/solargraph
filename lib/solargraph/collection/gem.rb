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
      # @param plugin_versions [Hash{String => String, nil}] Solargraph plugin
      #   gem name => version, nil when the plugin was not loaded from a gem,
      #   for the workspace the gem is mapped for; selects the gem cache
      #   directory (see {Workspace#plugin_versions})
      def initialize metagem, plugin_versions = {}
        super()
        @metagem = metagem
        @plugin_versions = plugin_versions
      end

      def cache_file
        File.join CacheDir.gem_dir(@plugin_versions), "#{metagem.cache_name}.ser"
      end

      def load
        return super if metagem.cacheable?
        @@path_source_cache[metagem.full_path] ||= pins
      end

      def pins
        @pins ||= without_yard
      end

      # @param metagem [Metagem]
      # @param plugin_versions [Hash{String => String, nil}] Solargraph plugin
      #   gem name => version, nil when the plugin was not loaded from a gem;
      #   selects the gem cache directory (see {Workspace#plugin_versions})
      def self.cached? metagem, plugin_versions = {}
        metagem.cacheable? && File.exist?(new(metagem, plugin_versions).cache_file)
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

        # Generating an ApiMap is necessary for processing macros
        bench = Bench.new(source_maps: source_maps)
        source_pins = ApiMap.new.catalog(bench).pins.select { |pin| files.include?(pin.filename) }

        rbs_pins = RbsMap::Gem.pins(metagem)
        RbsMap::Helpers.combine(source_pins, rbs_pins)
      end
    end
  end
end
