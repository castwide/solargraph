# frozen_string_literal: true

require 'set'

module Solargraph
  # @todo This class might need a way to track changes to the repo, e.g.,
  #   bundle or dependency updates
  #
  class External
    # @return [String, nil]
    attr_reader :directory

    # @return [Array<String>]
    attr_reader :requires

    # @param directory [String, nil]
    # @param requires [Array<String>]
    def initialize directory, requires
      @repo = Repo.new(directory)
      @directory = directory
      @requires = requires
      update!
    end

    # @return [Array<String>]
    def unresolved_requires
      @unresolved_requires ||= []
    end

    # @return [Array<String>]
    def unresolved_dependencies
      @unresolved_dependencies ||= []
    end

    # @return [Set<Metagem>]
    def loaded_gems
      @loaded_gems ||= Set.new
    end

    # @return [Set<Metagem>]
    def unloaded_gems
      @unloaded_gems ||= Set.new
    end

    # @return [Set<String>]
    def loaded_stdlibs
      @loaded_stdlibs ||= Set.new
    end

    # @return [Array<Pin::Base>]
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
      @rbs_collection_paths ||= read_rbs_collection_paths
    end

    # @return [String, nil]
    def rbs_collection_config_path
      # @todo Get rid of the '*' case
      # @sg-ignore a nil? guard does not narrow a method call, only a local
      @rbs_collection_config_path ||= unless directory.nil? || directory.empty? || directory == '*'
                                        yaml_file = File.join(directory, 'rbs_collection.yaml')
                                        yaml_file if File.file?(yaml_file)
                                      end
    end

    private

    # @return [void]
    def update!
      @generation = generation + 1
      clear_all
      load_requires
      load_rbs_collection
    end

    def cache_changed?
      unloaded_gems.any? { |gem| Collection::Gem.cached?(gem) }
    end

    # @return [void]
    def load_requires
      bundler_require = false

      requires.uniq.each do |path|
        if path == 'bundler/require'
          bundler_require = true
        end
        if RbsMap::Stdlib.has?(path)
          # @sg-ignore https://github.com/castwide/solargraph/pull/1400
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

    # @return [RbsCollection]
    def rbs_collection
      @rbs_collection ||= RbsCollection.new(rbs_collection_lockfile)
    end

    # @return [String, nil]
    def rbs_collection_lockfile
      # @sg-ignore https://github.com/castwide/solargraph/pull/1258
      return if directory.nil? || directory.empty? || directory == '*'
      lockfile = File.join(directory, 'rbs_collection.lock.yaml')
      lockfile if File.file?(lockfile)
    end

    # Signature sets for the Ruby stdlib are part of a collection's lockfile
    # but are not associated with any gem in the bundle, so the gem lookup in
    # #load_rbs_collection never finds them. Load them from the rbs gem.
    #
    # @return [void]
    def load_collection_stdlibs
      rbs_collection.stdlib_names.each do |library|
        next if loaded_stdlibs.include? library
        next unless RbsMap::Stdlib.has? library
        loaded_stdlibs.add library
        # @sg-ignore https://github.com/castwide/solargraph/pull/1400
        pins.concat Collection::Stdlib.load(library)
      end
    end

    # @return [void]
    def load_rbs_collection
      load_collection_stdlibs
      loaded_gems.each do |metagem|
        rbsc_pins = rbs_collection.load(metagem)
        # @todo Combining the pins is necessary because concatenating them
        #   breaks deep type inference in some cases
        pins.replace(RbsMap::Helpers.combine(pins, rbsc_pins)) unless rbsc_pins.empty?
      end
    end

    # @return [void]
    def clear_all
      pins.clear
      unresolved_requires.clear
      unresolved_dependencies.clear
      loaded_gems.clear
      unloaded_gems.clear
      loaded_stdlibs.clear
    end

    # @param metagem [Metagem]
    # @return [void]
    def process_gem metagem
      return if loaded_gems.include?(metagem) || unloaded_gems.include?(metagem)

      if metagem.cacheable?
        if Collection::Gem.cached?(metagem)
          loaded_gems.add metagem
          # @sg-ignore https://github.com/castwide/solargraph/pull/1400
          pins.concat Collection::Gem.load(metagem)
        else
          unloaded_gems.add metagem
        end
      else
        loaded_gems.add metagem
        # @sg-ignore https://github.com/castwide/solargraph/pull/1400
        pins.concat Collection::Gem.load(metagem)
      end
      load_dependencies metagem
    end

    # @param parent [Metagem]
    # @return [void]
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
