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
        if File.exist?(cache_file)
          Marshal.load(File.read(cache_file, mode: 'rb'))
        else
          serial = Marshal.dump(pins)
          FileUtils.mkdir_p File.dirname(cache_file)
          File.write cache_file, serial, mode: 'wb'
          pins
        end
      end

      # @return [Array<Pin::Base>]
      def self.load(...)
        new(...).load
      end

      def self.uncache(...)
        FileUtils.rm_f new(...).cache_file
      end
    end
  end
end
