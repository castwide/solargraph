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
        super
      end

      def gems
        return @pins if @pins
        cached_pins = PinCache.deserialize_stdlib_require library
        if cached_pins
          @pins = cached_pins
          @resolved = true
          logger.warn { "Deserialized #{cached_pins.length} cached pins for stdlib require #{library.inspect}" }
          cached_pins
        else
          generated_pins = load_environment_to_pins(loader)
          unless resolved?
            logger.warn { "Could not resolve #{library.inspect}" }
            return []
          end
          PinCache.serialize_stdlib_require library, generated_pins
          @pins = generated_pins
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
