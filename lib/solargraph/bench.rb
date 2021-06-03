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
    attr_reader :source_gems

    # @return [String]
    attr_reader :directory

    # @param source_maps [Array<SourceMap>, Set<SourceMap>]
    # @param load_paths [Array<String>, Set<String>]
    # @param source_gems [Array<String>, Set<String>]
    def initialize source_maps: [], load_paths: [], source_gems: [], directory: ''
      @source_maps = source_maps.to_set
      @load_paths = load_paths.to_set
      @source_gems = source_gems.to_set
      @directory = directory
    end
  end
end
