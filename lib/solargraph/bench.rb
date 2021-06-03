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
    # @param external_requires [Array<String>, Set<String>, nil]
    # @param directory [String]
    def initialize source_maps: [], load_paths: [], source_gems: [], external_requires: nil, directory: ''
      @source_maps = source_maps.to_set
      @load_paths = load_paths.to_set
      @source_gems = source_gems.to_set
      @external_requires = external_requires ? external_requires.to_set : nil
      @directory = directory
    end

    # @todo The external requires are only calculated here if they weren't
    #   received at initialization. This seems unnecessarily confusing. It
    #   probably makes more sense to depend on whatever value was received.
    # @return [Set<String>]
    def external_requires
      @external_requires ||= source_maps.map { |map| find_external_requires(map) }
        .flatten
        .to_set
    end

    private

    def filenames
      @filenames ||= source_maps.map(&:filename).to_set
    end

    # @param source_map [SourceMap]
    def find_external_requires source_map
      new_set = source_map.requires.map(&:name).to_set
      # return if new_set == source_map_external_require_hash[source_map.filename]
      new_set.reject do |path|
        load_paths.any? do |base|
          full = Pathname.new(base).join("#{path}.rb").to_s
          filenames.include?(full)
        end
      end
    end
  end
end
