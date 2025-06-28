# frozen_string_literal: true

require 'pathname'
require 'rbs'

module Solargraph
  class RbsMap
    autoload :Conversions, 'solargraph/rbs_map/conversions'
    autoload :CoreMap,     'solargraph/rbs_map/core_map'
    autoload :CoreFills,   'solargraph/rbs_map/core_fills'
    autoload :StdlibMap,   'solargraph/rbs_map/stdlib_map'

    include Logging

    # @type [Hash{String => RbsMap}]
    @@rbs_maps_hash = {}

    attr_reader :library

    attr_reader :rbs_collection_paths

    attr_reader :rbs_collection_config_path

    # @param library [String]
    # @param version [String, nil]
    # @param rbs_collection_paths [Array<Pathname, String>]
    def initialize library, version = nil, rbs_collection_config_path: nil, rbs_collection_paths: []
      if rbs_collection_config_path.nil? && !rbs_collection_paths.empty?
        raise 'Please provide rbs_collection_config_path if you provide rbs_collection_paths'
      end
      @library = library
      @version = version
      @rbs_collection_config_path = rbs_collection_config_path
      @rbs_collection_paths = rbs_collection_paths
      add_library loader, library, version
    end

    def loader
      @loader ||= RBS::EnvironmentLoader.new(core_root: nil, repository: repository)
    end

    # @return string representing the version of the RBS info fetched
    #   for the given library.  Must change when the RBS info is
    #   updated upstream for the same library and version.  May change
    #   if the config for where information comes form changes.
    def cache_key
      @hextdigest ||= begin
        data = nil
        if rbs_collection_config_path
          lockfile_path = RBS::Collection::Config.to_lockfile_path(Pathname.new(rbs_collection_config_path))
          if lockfile_path.exist?
            collection_config = RBS::Collection::Config.from_path lockfile_path
            gem_config = collection_config.gem(library)
            data = gem_config&.to_s
          end
        end
        if data.nil? || data.empty?
          if resolved?
            # definitely came from the gem itself and not elsewhere -
            # only one version per gem
            'gem-export'
          else
            'unresolved'
          end
        else
          Digest::SHA1.hexdigest(data)
        end
      end
    end

    def self.from_gemspec gemspec, rbs_collection_path, rbs_collection_config_path
      rbs_map = RbsMap.new(gemspec.name, gemspec.version,
                           rbs_collection_paths: [rbs_collection_path].compact,
                           rbs_collection_config_path: rbs_collection_config_path)
      return rbs_map if rbs_map.resolved?

      # try any version of the gem in the collection
      RbsMap.new(gemspec.name, nil,
                 rbs_collection_paths: [rbs_collection_path].compact,
                 rbs_collection_config_path: rbs_collection_config_path)
    end

    def pins
      @pins ||= resolved? ? conversions.pins : []
    end

    # @generic T
    # @param path [String]
    # @param klass [Class<generic<T>>]
    # @return [generic<T>, nil]
    def path_pin path, klass = Pin::Base
      pin = pins.find { |p| p.path == path }
      pin if pin&.is_a?(klass)
    end

    # @param path [String]
    # @return [Array<Pin::Base>]
    def path_pins path
      pins.select { |p| p.path == path }
    end

    def resolved?
      @resolved
    end

    def repository
      @repository ||= RBS::Repository.new(no_stdlib: false).tap do |repo|
        @rbs_collection_paths.each do |dir|
          dir_path = Pathname.new(dir)
          repo.add(dir_path) if dir_path.exist? && dir_path.directory?
        end
      end
    end

    # @param library [String]
    # @return [RbsMap]
    def self.load library
      @@rbs_maps_hash[library] ||= RbsMap.new(library)
    end

    private

    def loader
      @loader ||= RBS::EnvironmentLoader.new(core_root: nil, repository: repository)
    end

    def conversions
      @conversions ||= Conversions.new(loader: loader)
    end

    # @param loader [RBS::EnvironmentLoader]
    # @param library [String]
    # @return [Boolean] true if adding the library succeeded
    def add_library loader, library, version
      @resolved = if loader.has_library?(library: library, version: version)
        loader.add library: library, version: version
        logger.debug { "#{short_name} successfully loaded library #{library}:#{version}" }
        true
      else
        logger.info { "#{short_name} did not find data for library #{library}:#{version}" }
        false
      end
    end

    # @return [String]
    def short_name
      self.class.name.split('::').last
    end
  end
end
