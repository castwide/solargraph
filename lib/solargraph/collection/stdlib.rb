# frozen_string_literal: true

module Solargraph
  module Collection
    # Cacheable stdlib pins.
    #
    class Stdlib < Base
      attr_reader :library

      # @param library [String]
      def initialize library
        @library = library
      end

      def pins
        RbsMap::Stdlib.pins(library)
      end

      def cache_file
        File.join CacheDir.stdlib_dir, "#{library}.ser"
      end
    end
  end
end
