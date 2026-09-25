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
      @rbs_collection_paths ||= read_rbs_collection_paths
    end

    # @return [String, nil]
    def rbs_collection_config_path
      # @todo Get rid of the '*' case
      @rbs_collection_config_path ||= unless directory.nil? || directory.empty? || directory == '*'
                                        yaml_file = File.join(directory, 'rbs_collection.yaml')
                                        yaml_file if File.file?(yaml_file)
                                      end
    end

    private

    def update!
      clear_all
      load_requires
      load_rbs_collection
    end

    def cache_changed?
      unloaded_gems.any? { |gem| Collection::Gem.cached?(gem) }
    end

    def load_requires
      bundler_require = false

      requires.each do |path|
        if path == 'bundler/require'
          bundler_require = true
        end
        if RbsMap::Stdlib.has?(path)
          Collection::Stdlib.load(path)
        else
          metagem = @repo.find_by_path(path)
          next unresolved_requires.push(path) unless metagem
          process_gem metagem
        end
      end

      return unless bundler_require

      @repo.bundled.each do |metagem|
        next if loaded_gems.include?(metagem) || unloaded_gems.include?(metagem)
        process_gem metagem
      end
    end

    def load_rbs_collection
      rbs_collection_pins = rbs_collection_paths.flat_map { |path| RbsMap::Path.pins(path) }
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
      if metagem.cacheable?
        if Collection::Gem.cached?(metagem)
          pins.concat(Collection::Gem.load(metagem)) if loaded_gems.add?(metagem)
        else
          unloaded_gems.add metagem
        end
      else
        pins.concat(Collection::Gem.load(metagem)) if loaded_gems.add?(metagem)
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

    # @return [Array<String>]
    def read_rbs_collection_paths
      return [] unless rbs_collection_config_path

      yaml = YAML.load_file(rbs_collection_config_path)
      [File.expand_path(yaml.fetch('path'), directory)].concat(
        yaml.fetch('sources', [])
            .select { |source| source['type'] == 'local' && source['path'] }
            .map { |source| File.expand_path(source['path'], directory) }
      ).compact
    end
  end
end
