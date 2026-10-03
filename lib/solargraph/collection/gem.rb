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
        super()
        @metagem = metagem
      end

      def cache_file
        File.join CacheDir.gem_dir, "#{metagem.cache_name}.ser"
      end

      # @sg-ignore a singleton .load with no declared return falls back to Kernel#load
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
      def self.cached? metagem
        metagem.cacheable? && File.exist?(new(metagem).cache_file)
      end

      private

      # @return [Array<Pin::Base>]
      def cacheable_pins
        code_objects = Yardoc.load!(metagem)
        yard_pins = YardMap::Mapper.new(code_objects, metagem).map
        # @sg-ignore https://github.com/castwide/solargraph/issues/1108
        rbs_pins = RbsMap::Gem.pins(metagem)
        RbsMap::Helpers.combine(yard_pins, rbs_pins)
      end

      # @return [Array<Pin::Base>]
      def uncacheable_pins
        files = metagem.require_paths.flat_map { |path| Dir.glob(File.join(metagem.full_path, path, '**', '*.rb')) }
        source_maps = files.map { |file| Solargraph::SourceMap.load(file) }
        source_pins = source_maps.flat_map(&:pins)
        # @sg-ignore https://github.com/castwide/solargraph/issues/1108
        rbs_pins = RbsMap::Gem.pins(metagem)
        RbsMap::Helpers.combine(source_pins, rbs_pins)
      end
    end
  end
end
