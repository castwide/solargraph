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

      # @param rebuild [Boolean] build pins regardless of whether we
      #   have cached them already
      # @param library [String]
      # @param out [StringIO, IO, nil] where to log messages
      def initialize library, rebuild: false, out: $stderr
        cached_pins = PinCache.deserialize_stdlib_require library
        if cached_pins && !rebuild
          @pins = cached_pins
          @resolved = true
          @loaded = true
          logger.debug { "Deserialized #{cached_pins.length} cached pins for stdlib require #{library.inspect}" }
        elsif self.class.source.has? library, nil
          super(library, out: out)
          unless resolved?
            @pins = []
            logger.debug { "StdlibMap could not resolve #{library.inspect}" }
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
          # @sg-ignore we are relying on undocumented behavior where
          #   passing version=nil gives the latest version it has
          source.dependencies_of(name, version)
        else
          []
        end
      end

      def resolve_dependencies?
        # there are 'virtual' dependencies for stdlib gems in RBS that
        # aren't represented in the actual gemspecs that we'd
        # otherwise use
        true
      end

      # @param library [String]
      # @return [StdlibMap]
      def self.load library
        @stdlib_maps_hash[library] ||= StdlibMap.new(library)
      end
    end
  end
end
