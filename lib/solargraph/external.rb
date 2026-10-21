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

    # @return [Array<String>]
    attr_reader :extra_gem_names

    # @param directory [String]
    # @param requires [Array<String>]
    # @param extra_gem_names [Array<String>]
    def initialize directory, requires, extra_gem_names = []
      @repo = Repo.new(directory)
      @directory = directory
      @requires = requires
      @extra_gem_names = extra_gem_names
      update!
    end

    # @return [Array<String>]
    def configured_gem_names
      loaded_gems.map(&:name) + unloaded_gems.map(&:name) + extra_gem_names
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

    # @return [Array<String>]
    def unfound_gem_names
      @unfound_gem_names ||= []
    end

    def loaded_stdlibs
      @loaded_stdlibs ||= Set.new
    end

    def pins
      @pins ||= []
    end

    # @return [Integer] incremented whenever the external pin set is rebuilt
    def generation
      @generation ||= 0
    end

    # @param new_requires [Array<String>]
    # @param new_gem_names [Array<String>]
    # @return [Boolean]
    def update new_requires, new_gem_names = []
      return false if requires == new_requires && new_gem_names == extra_gem_names && !cache_changed?

      requires.replace new_requires
      extra_gem_names.replace new_gem_names
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
      @generation = generation + 1
      clear_all
      load_requires
      load_gem_names
      # load_rbs_collection
    end

    def cache_changed?
      unloaded_gems.any? { |gem| Collection::Gem.cached?(gem) }
    end

    def load_requires
      bundler_require = false

      requires.uniq.each do |path|
        if path == 'bundler/require'
          bundler_require = true
        end
        if RbsMap::Stdlib.has?(path)
          pins.concat Collection::Stdlib.load(path) if loaded_stdlibs.add?(path)
        else
          metagem = @repo.find_by_path(path)
          next unresolved_requires.push(path) unless metagem
          process_gem metagem
        end
      end

      return unless bundler_require

      @repo.find_by_group(:default).each { |metagem| process_gem metagem }
    end

    # @return [void]
    def load_gem_names
      extra_gem_names.uniq.each do |gem|
        metagem = @repo.find_by_name(gem)
        next unfound_gem_names.push(gem) unless metagem
        process_gem metagem
      end
    end

    def rbs_collection
      @rbs_collection ||= RbsCollection.new(rbs_collection_lockfile)
    end

    def rbs_collection_lockfile
      return if directory.nil? || directory.empty? || directory == '*'
      lockfile = File.join(directory, 'rbs_collection.lock.yaml')
      lockfile if File.file?(lockfile)
    end

    def clear_all
      pins.clear
      unresolved_requires.clear
      unresolved_dependencies.clear
      loaded_gems.clear
      unloaded_gems.clear
      loaded_stdlibs.clear
      unfound_gem_names.clear
    end

    def process_gem metagem
      return if loaded_gems.include?(metagem) || unloaded_gems.include?(metagem)

      if metagem.cacheable? && !Collection::Gem.cached?(metagem)
        unloaded_gems.add metagem
      else
        loaded_gems.add metagem
        base_pins = Collection::Gem.load(metagem)
        rbsc_pins = rbs_collection.load(metagem)
        if rbsc_pins.empty?
          pins.concat base_pins
        else
          pins.concat RbsMap::Helpers.combine(base_pins, rbsc_pins)
        end
        # Gems might not declare stdlib dependencies as gem dependencies
        # (e.g., `activesupport` requires `date`)
        base_pins.select { |pin| pin.is_a?(Pin::Reference::Require) && RbsMap::Stdlib.has?(pin.name) }
                 .each do |pin|
                   pins.concat Collection::Stdlib.load(pin.name) if loaded_stdlibs.add?(pin.name)
                 end
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
