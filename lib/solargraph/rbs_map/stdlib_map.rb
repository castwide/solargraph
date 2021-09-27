require 'rbs'
require 'set'

module Solargraph
  class RbsMap
    class StdlibMap < RbsMap
      # @type [Hash{String => RbsMap}]
      @@stdlib_maps_hash = {}

      # @param library [String]
      # @return [StdlibMap]
      def self.load library
        @@stdlib_maps_hash[library] ||= StdlibMap.new(library)
      end

      def repository
        @repository ||= RBS::Repository.new
      end
    end
  end
end
