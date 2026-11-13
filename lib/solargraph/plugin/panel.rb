# frozen_string_literal: true

module Solargraph
  module Plugin
    class Panel
      attr_reader :source_maps, :live_map, :gem_names

      # @param source_maps [Set<SourceMap>, Array<SourceMap>]
      # @param live_map [SourceMap, nil]
      # @param gem_names [Array<String>]
      def initialize source_maps: [], live_map: nil, gem_names: []
        @source_maps = source_maps
        @live_map = live_map
        @gem_names = gem_names
      end

      # @return [Array<Pin::Base>]
      def pins
        @pins ||= source_maps.flat_map(&:pins)
      end

      # @param klass [Class<Pin::Base>]
      # @return [Set<Pin::Base>, Array<Pin::Base>]
      def pins_by_class klass
        pin_class_hash[klass] || []
      end

      # @param path [String]
      # @return [Set<Pin::Base>, Array<Pin::Base>]
      def pins_by_path path
        pin_path_hash[path] || []
      end

      private

      # @return [Hash{Class => Set<Pin::Base>}]
      def pin_class_hash
        @pin_class_hash ||= pins.to_set.classify(&:class)
      end

      # @return [Hash{String => Set<Pin::Base>}]
      def pin_path_hash
        @pin_path_hash ||= pins.to_set.classify(&:path)
      end
    end
  end
end
