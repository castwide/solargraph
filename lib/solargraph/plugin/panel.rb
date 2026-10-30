# frozen_string_literal: true

module Solargraph
  module Plugin
    class Panel
      attr_reader :source_maps, :live_map, :gem_names

      # @return [Array<Pin::Base>] pins from gems and stdlib
      attr_reader :external_pins

      # @param source_maps [Set<SourceMap>, Array<SourceMap>]
      # @param live_map [SourceMap, nil]
      # @param gem_names [Array<String>]
      # @param external_pins [Array<Pin::Base>]
      def initialize source_maps: [], live_map: nil, gem_names: [], external_pins: []
        @source_maps = source_maps
        @live_map = live_map
        @gem_names = gem_names
        @external_pins = external_pins
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
