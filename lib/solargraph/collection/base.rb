# frozen_string_literal: true

require 'fileutils'

module Solargraph
  module Collection
    # The base class for cacheable pin collections. Subclasses need to
    # implement #pins and #cache_file.
    #
    # @!method pins
    #   The array of pins for this collection.
    #   @abstract
    #   @return [Array<Pin::Base>]
    # @!method cache_file
    #   The file that will store serialized pins.
    #   @abstract
    #   @return [String]
    class Base
      # @return [Array<Pin::Base>]
      def load
        Collection.cached(cache_file) { file_cache_pins || generate_pin_caches }
      end

      # @return [Array<Pin::Base>]
      def self.load(...)
        new(...).load
      end

      def self.uncache(...)
        cache_file = new(...).cache_file
        FileUtils.rm_rf cache_file
        Collection.mem_cache.delete cache_file
      end

      private

      # @return [Array<Pin::Base>, nil]
      def file_cache_pins
        return nil unless File.exist?(cache_file)

        # @type [Object]
        loaded = Marshal.load(File.read(cache_file, mode: 'rb')) # rubocop:disable Security/MarshalLoad
        # @param pin [Object]
        return loaded.map { |pin| pin.is_a?(Pin::Base) ? pin : raise(TypeError, "#{cache_file} contains a non-pin") } if loaded.is_a?(Array)

        raise TypeError, "#{cache_file} does not contain an array of pins"
      end

      def generate_pin_caches
        Collection.mem_cache[cache_file] = pins
        serial = Marshal.dump(pins)
        FileUtils.mkdir_p File.dirname(cache_file)
        File.write cache_file, serial, mode: 'wb'
        pins
      end
    end
  end
end
