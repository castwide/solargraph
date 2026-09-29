# frozen_string_literal: true

require 'set'

module Solargraph
  # @todo This class might need a way to track changes to the repo, e.g.,
  #   bundle or dependency updates
  #
  class External
    # @return [String]
    attr_reader :directory

    # @return [Array<String>]
    attr_reader :requires

    # @param directory [String]
    # @param requires [Array<String>]
    def initialize directory, requires
      @repo = Repo.new(directory)
      @directory = directory
      @requires = requires
      update!
    end

    def unresolved_requires
      @unresolved_requires ||= []
    end

    def unresolved_dependencies
      @unresolved_dependencies ||= []
    end

    def loaded_gems
      @loaded_gems ||= Set.new
    end

    def unloaded_gems
      @unloaded_gems ||= Set.new
    end

    def pins
      @pins ||= []
    end

    # @return [Integer] incremented whenever the external pin set is rebuilt
    def generation
      @generation ||= 0
    end

    # @param new_requires [Array<String>]
    # @return [Boolean]
    def update new_requires
      return false if requires == new_requires && !cache_changed?

      requires.replace new_requires
      update!
      true
    end

    # @return [Array<String>]
    def rbs_collection_paths
      @rbs_collection_paths ||= RbsCollection.paths(directory)
    end

    # @return [String, nil]
    def rbs_collection_config_path
      @rbs_collection_config_path ||= RbsCollection.config_path(directory)
    end

    # Whether the workspace's collection carries this gem's signatures, which
    # decides what a cached copy of it holds.
    #
    # @param metagem [Metagem]
    # @return [Boolean]
    def rbs_collection_carries? metagem
      RbsCollection.provides?(directory, metagem.name)
    end

    private

    def update!
      @generation = generation + 1
      clear_all
      load_requires
      load_rbs_collection
    end

    def cache_changed?
      unloaded_gems.any? { |gem| Collection::Gem.cached?(gem, rbs_collection: rbs_collection_carries?(gem)) }
    end

    def load_requires
      bundler_require = false

      requires.uniq.each do |path|
        if path == 'bundler/require'
          bundler_require = true
        end
        if RbsMap::Stdlib.has?(path)
          pins.concat Collection::Stdlib.load(path)
        else
          metagem = @repo.find_by_path(path)
          next unresolved_requires.push(path) unless metagem
          process_gem metagem
        end
      end

      return unless bundler_require

      @repo.find_by_group(:default).each { |metagem| process_gem metagem }
    end

    def load_rbs_collection
      rbs_collection_pins = rbs_collection_paths.flat_map { |path| Collection::Rbs.load(path) }
      pins.replace RbsMap::Helpers.combine(pins, rbs_collection_pins)
    end

    def clear_all
      pins.clear
      unresolved_requires.clear
      unresolved_dependencies.clear
      loaded_gems.clear
      unloaded_gems.clear
    end

    def process_gem metagem
      return if loaded_gems.include?(metagem) || unloaded_gems.include?(metagem)

      carried = rbs_collection_carries?(metagem)
      if metagem.cacheable?
        if Collection::Gem.cached?(metagem, rbs_collection: carried)
          loaded_gems.add metagem
          pins.concat Collection::Gem.load(metagem, rbs_collection: carried)
        else
          unloaded_gems.add metagem
        end
      else
        loaded_gems.add metagem
        pins.concat Collection::Gem.load(metagem, rbs_collection: carried)
      end
      load_dependencies metagem
    end

    def load_dependencies parent
      parent.dependencies.each do |name|
        next if loaded_gems.map(&:name).include?(name) || unloaded_gems.map(&:name).include?(name)
        metagem = @repo.find_by_name(name)
        next unresolved_dependencies.push(name) unless metagem
        process_gem metagem
      end
    end
  end
end
