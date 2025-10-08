# frozen_string_literal: true

require 'rbs'

module Solargraph
  class RbsMap
    # Ruby stdlib pins
    #
    class StdlibMap < RbsMap
      include Logging

      # @type [Hash{String => RbsMap}]
      @stdlib_maps_hash = {}

      # @param library [String]
      def initialize library
        cached_pins = PinCache.deserialize_stdlib_require library
        if cached_pins
          @pins = cached_pins
          @resolved = true
          @loaded = true
          logger.debug { "Deserialized #{cached_pins.length} cached pins for stdlib require #{library.inspect}" }
        else
          super
          unless resolved?
            @pins = []
            logger.info { "Could not resolve #{library.inspect}" }
            return
          end
          generated_pins = pins
          logger.debug { "Found #{generated_pins.length} pins for stdlib library #{library}" }
          PinCache.serialize_stdlib_require library, generated_pins
        end
      end

      # @return [RBS::Collection::Sources::Stdlib]
      def self.source
        @source ||= RBS::Collection::Sources::Stdlib.instance
      end

      # @param name [String]
      # @param version [String, nil]
      # @return [Array<Hash{String => String}>, nil]
      def self.stdlib_dependencies name, version = nil
        if source.has?(name, version)
          source.dependencies_of(name, version)
        else
          []
        end
      end

      # @param library [String]
      # @return [StdlibMap]
      def self.load library
        @stdlib_maps_hash[library] ||= StdlibMap.new(library)
      end
    end
  end
end
