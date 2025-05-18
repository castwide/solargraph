# frozen_string_literal: true


module Solargraph
  # A container of source maps and workspace data to be cataloged in an ApiMap.
  #
  class Bench
    # @return [Set<SourceMap>]
    attr_reader :source_maps

    # @return [Workspace]
    attr_reader :workspace

    # @return [SourceMap]
    attr_reader :live_map

    # @return [Set<String>]
    attr_reader :external_requires

    # @param source_maps [Array<SourceMap>, Set<SourceMap>]
    # @param workspace [Workspace]
    # @param live_map [SourceMap, nil]
    # @param external_requires [Array<String>, Set<String>]
    def initialize source_maps: [], workspace: Workspace.new, live_map: nil, external_requires: []
      @source_maps = source_maps.to_set
      @workspace = workspace
      @live_map = live_map
      @external_requires = external_requires.reject { |path| workspace.would_require?(path) }
                                            .compact
                                            .to_set
    end

    # @return [Hash{String => SourceMap}]
    def source_map_hash
      # @todo Work around #to_h bug in current Ruby head (3.5) with #map#to_h
      @source_map_hash ||= source_maps.map { |s| [s.filename, s] }
                                      .to_h
    end

    def icebox
      @icebox ||= (source_maps - [live_map])
    end
  end
end
