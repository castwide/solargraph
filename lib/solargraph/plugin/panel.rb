# frozen_string_literal: true

module Solargraph
  module Plugin
    class Panel
      # @return [Enumerable<SourceMap>]
      attr_reader :source_maps

      # @return [SourceMap, nil]
      attr_reader :live_map

      # @return [Array<String>]
      attr_reader :gem_names

      # @param source_maps [Enumerable<SourceMap>]
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

      # @generic T
      # @param klass [Class<generic<T>>]
      # @return [Enumerable<generic<T>>]
      def pins_by_class klass
        pin_class_hash[klass] || []
      end

      # @param path [String]
      # @return [Enumerable<Pin::Base>]
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
