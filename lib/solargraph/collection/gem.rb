# frozen_string_literal: true

module Solargraph
  module Collection
    # Cacheable gem pins.
    #
    class Gem < Base
      include Logging

      # Gems whose YARD build costs far more than the pins are worth once an
      # RBS collection carries their signatures; `parser` alone takes over a
      # minute.
      YARD_SUPPRESSED_GEMS = ['parser'].freeze

      attr_reader :metagem

      # @param metagem [Metagem]
      # @param rbs_collection [Boolean] whether a collection carries this gem
      def initialize metagem, rbs_collection: false
        super()
        @metagem = metagem
        @suppress_yard = rbs_collection && YARD_SUPPRESSED_GEMS.include?(metagem.name)
      end

      # A gem read without its YARD documentation holds different pins from
      # one read with it, so the two cannot share an entry.
      def cache_file
        suffix = suppress_yard? ? '-rbs-only' : ''
        File.join CacheDir.gem_dir, "#{metagem.cache_name}#{suffix}.ser"
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

      # @param metagem [Metagem]
      # @param rbs_collection [Boolean]
      # @return [Boolean]
      def self.cached? metagem, rbs_collection: false
        metagem.cacheable? && File.exist?(new(metagem, rbs_collection: rbs_collection).cache_file)
      end

      # Asking for a gem by name means every entry it has, not the one this
      # workspace would have written.
      #
      # @param metagem [Metagem]
      # @return [void]
      def self.uncache metagem
        new(metagem).uncache
        new(metagem, rbs_collection: true).uncache
      end

      private

      # @return [Boolean]
      def suppress_yard?
        @suppress_yard
      end

      def cacheable_pins
        rbs_pins = RbsMap::Gem.pins(metagem)
        return rbs_pins if suppress_yard?

        code_objects = Yardoc.load!(metagem)
        yard_pins = YardMap::Mapper.new(code_objects, metagem).map
        RbsMap::Helpers.combine(yard_pins, rbs_pins)
      end

      def uncacheable_pins
        files = metagem.require_paths.flat_map { |path| Dir.glob(File.join(metagem.full_path, path, '**', '*.rb')) }
        source_maps = files.map { |file| Solargraph::SourceMap.load(file) }
        source_pins = source_maps.flat_map(&:pins)
        rbs_pins = RbsMap::Gem.pins(metagem)
        RbsMap::Helpers.combine(source_pins, rbs_pins)
      end
    end
  end
end
