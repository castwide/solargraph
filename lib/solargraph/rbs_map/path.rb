# frozen_string_literal: true

module Solargraph
  module RbsMap
    class Path < Base
      # @return [void]
      def self.uncache
        cache.clear
      end

      # @param path [String]
      # @return [Array<Pin::Base>]
      def self.pins path
        cache[path] ||= new(path).pins
      end

      # Converted pins per collection path. External#update rebuilds its pin
      # set on every catalog, and converting a collection costs more than the
      # rest of the map put together.
      #
      # @return [Hash{String => Array<Pin::Base>}]
      def self.cache
        @cache ||= {}
      end
      private_class_method :cache

      # @param path [String]
      def initialize path
        super()
        loader.add path: Pathname.new(path)
      end
    end
  end
end
