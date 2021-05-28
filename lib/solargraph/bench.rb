# frozen_string_literal: true

module Solargraph
  # A container of source maps and gem specs to be cataloged in an ApiMap.
  #
  class Bench
    attr_reader :source_maps

    attr_reader :load_paths

    attr_reader :gemnames

    def initialize source_maps: [], load_paths: [], gemnames: []
      @source_maps = source_maps.to_set
      @load_paths = load_paths.to_set
      @gemnames = gemnames.to_set
    end
  end
end
