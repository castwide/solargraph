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
      # @sg-ignore https://github.com/castwide/solargraph/issues/1108
      def self.load(...)
        # @sg-ignore https://github.com/castwide/solargraph/issues/1108
        new(...).load
      end

      # @return [void]
      # @sg-ignore https://github.com/castwide/solargraph/issues/1108
      def self.uncache(...)
        # @sg-ignore https://github.com/castwide/solargraph/issues/1108
        cache_file = new(...).cache_file
        # @sg-ignore https://github.com/castwide/solargraph/issues/1255
        FileUtils.rm_rf cache_file
        Collection.mem_cache.delete cache_file
      end

      private

      # @return [Array<Pin::Base>, nil]
      # @sg-ignore a singleton .load with no declared return falls back to Kernel#load
      def file_cache_pins
        Marshal.load(File.read(cache_file, mode: 'rb')) if File.exist?(cache_file) # rubocop:disable Security/MarshalLoad
      end

      # @return [Array<Pin::Base>]
      def generate_pin_caches
        Collection.mem_cache[cache_file] = pins
        serial = Marshal.dump(pins)
        # @sg-ignore https://github.com/castwide/solargraph/issues/1255
        FileUtils.mkdir_p File.dirname(cache_file)
        File.write cache_file, serial, mode: 'wb'
        pins
      end
    end
  end
end
