# frozen_string_literal: true

require 'digest'
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
    # @param rbs_collection_config_path [String, Pathname, nil]
    # @param rbs_collection_paths [Array<Pathname, String>]
    # @param out [StringIO, IO, nil] where to log messages
    def initialize library, version = nil, rbs_collection_config_path: nil, rbs_collection_paths: [], out: $stderr
      if rbs_collection_config_path.nil? && !rbs_collection_paths.empty?
        raise 'Please provide rbs_collection_config_path if you provide rbs_collection_paths'
      end
      @library = library
      @version = version
      @rbs_collection_config_path = rbs_collection_config_path
      @rbs_collection_paths = rbs_collection_paths
      add_library loader, library, version
    end

    CACHE_KEY_GEM_EXPORT = 'gem-export'
    CACHE_KEY_UNRESOLVED = 'unresolved'
    CACHE_KEY_STDLIB = 'stdlib'
    CACHE_KEY_LOCAL = 'local'

    # @param cache_key [String, nil]
    # @return [String, nil] a description of the source of the RBS info
    def self.rbs_source_desc cache_key
      case cache_key
      when CACHE_KEY_GEM_EXPORT
        'RBS gem export'
      when CACHE_KEY_UNRESOLVED
        nil
      when CACHE_KEY_STDLIB
        'RBS standard library'
      when CACHE_KEY_LOCAL
        'local RBS shims'
      else
        'RBS collection'
      end
    end

    # @return [RBS::EnvironmentLoader]
    def loader
      @loader ||= RBS::EnvironmentLoader.new(core_root: nil, repository: repository)
    end

    # @return [String] representing the version of the RBS info fetched
    #   for the given library.  Must change when the RBS info is
    #   updated upstream for the same library and version.  May change
    #   if the config for where information comes form changes.
    def cache_key
      return CACHE_KEY_UNRESOLVED unless resolved?

      @hextdigest ||= begin
        # @type [String, nil]
        data = nil
        # @type gem_config [nil, Hash{String => Hash{String => String}}]
        gem_config = nil
        if rbs_collection_config_path
          # @sg-ignore flow sensitive typing needs to handle attrs
          lockfile_path = RBS::Collection::Config.to_lockfile_path(Pathname.new(rbs_collection_config_path))
          if lockfile_path.exist?
            collection_config = RBS::Collection::Config.from_path lockfile_path
            gem_config = collection_config.gem(library)
            data = gem_config&.to_s
          end
        end
        if gem_config.nil?
          CACHE_KEY_STDLIB
        else
          # @type [String]
          source = gem_config.dig('source', 'type')
          case source
          when 'rubygems'
            CACHE_KEY_GEM_EXPORT
          when 'local'
            CACHE_KEY_LOCAL
          when 'stdlib'
            CACHE_KEY_STDLIB
          else
            # @sg-ignore Need to add nil check here
            Digest::SHA1.hexdigest(data)
          end
        end
      end
    end

    # @param gemspec [Gem::Specification, Bundler::LazySpecification]
    # @param rbs_collection_path [String, Pathname, nil]
    # @param rbs_collection_config_path [String, Pathname, nil]
    # @return [RbsMap]
    def self.from_gemspec gemspec, rbs_collection_path, rbs_collection_config_path
      # prefers stdlib RBS if available
      rbs_map = RbsMap::StdlibMap.new(gemspec.name)
      return rbs_map if rbs_map.resolved?

      rbs_map = RbsMap.new(gemspec.name, gemspec.version,
                           rbs_collection_paths: [rbs_collection_path].compact,
                           rbs_collection_config_path: rbs_collection_config_path)
      return rbs_map if rbs_map.resolved?

      # try any version of the gem in the collection
      RbsMap.new(gemspec.name, nil,
                 rbs_collection_paths: [rbs_collection_path].compact,
                 rbs_collection_config_path: rbs_collection_config_path)
    end

    # @param out [IO, nil] where to log messages
    # @return [Array<Pin::Base>]
    def pins out: $stderr
      @pins ||= if resolved?
                  conversions.pins
                else
                  []
                end
    end

    # @generic T
    # @param path [String]
    # @param klass [Class<generic<T>>]
    #
    # @sg-ignore Need to be able to resolve generics based on a
    #   Class<generic<T>> param
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

    # @return [RBS::Repository]
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

    # @return [Conversions]
    def conversions
      @conversions ||= Conversions.new(loader: loader)
    end

    def resolve_dependencies?
      # we need to resolve dependencies via gemfile.lock manually for
      # YARD regardless, so use same mechanism here so we don't
      # duplicate work generating pins from dependencies
      false
    end

    # @param loader [RBS::EnvironmentLoader]
    # @param library [String]
    # @param version [String, nil] the version of the library to load, or nil for any
    # @param out [StringIO, IO, nil] where to log messages
    # @return [Boolean] true if adding the library succeeded
    def add_library loader, library, version, out: $stderr
      @resolved = if loader.has_library?(library: library, version: version)
                    loader.add library: library, version: version, resolve_dependencies: resolve_dependencies?
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
