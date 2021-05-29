# frozen_string_literal: true

require 'set'

module Solargraph
  # A container of source maps and gem specs to be cataloged in an ApiMap.
  #
  class Bench
    # @return [Set<SourceMap>]
    attr_reader :source_maps

    # @return [Set<String>]
    attr_reader :load_paths

    # @return [Set<String>]
    attr_reader :gemnames

    # @param source_maps [Array<SourceMap>, Set<SourceMap>]
    # @param load_paths [Array<String>, Set<String>]
    # @param gemnames [Array<String>, Set<String>]
    def initialize source_maps: [], load_paths: [], gemnames: []
      @source_maps = source_maps.to_set
      @load_paths = load_paths.to_set
      @gemnames = gemnames.to_set
    end
  end
end
