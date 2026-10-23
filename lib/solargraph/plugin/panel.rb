# frozen_string_literal: true

module Solargraph
  module Plugin
    class Panel
      attr_reader :source_maps, :live_map, :gem_names

      def initialize source_maps: [], live_map: nil, gem_names: []
        @source_maps = source_maps
        @live_map = live_map
        @gem_names = gem_names
      end

      def pins
        @pins ||= source_maps.flat_map(&:pins)
      end

      def pins_by_class klass
        pin_class_hash[klass] || []
      end

      def pins_by_path path
        pin_path_hash[path] || []
      end

      private

      def pin_class_hash
        @pin_class_hash ||= pins.to_set.classify(&:class)
      end

      def pin_path_hash
        @pin_path_hash ||= pins.to_set.classify(&:path)
      end
    end
  end
end
