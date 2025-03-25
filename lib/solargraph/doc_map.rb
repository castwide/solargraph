# frozen_string_literal: true

module Solargraph
  # A collection of pins generated from required gems.
  #
  class DocMap
    # @return [Array<String>]
    attr_reader :requires

    # @return [Array<Gem::Specification>]
    attr_reader :dependencies

    # @return [Array<Pin::Base>]
    attr_reader :pins

    # @return [Array<Gem::Specification>]
    attr_reader :uncached_gemspecs

    # @param requires [Array<String>]
    # @param dependencies [Array<Gem::Specification>]
    def initialize(requires, dependencies)
      @requires = requires
      @dependencies = dependencies
      generate
    end

    # @return [Array<Gem::Specification>]
    def gemspecs
      @gemspecs ||= required_gem_map.values.compact
    end

    # @return [Array<String>]
    def unresolved_requires
      @unresolved_requires ||= required_gem_map.select { |_, gemspec| gemspec.nil? }.keys
    end

    # @return [Hash{Gem::Specification => Array[Pin::Base]}]
    def self.gems_in_memory
      @gems_in_memory ||= {}
    end

    private

    # @return [Hash{String => Gem::Specification, nil}]
    def required_gem_map
      @required_gem_map ||= requires.to_h { |path| [path, resolve_path_to_gemspec(path)] }
    end

    # @return [Hash{String => Gem::Specification}]
    def dependency_map
      @dependency_map ||= dependencies.to_h { |gemspec| [gemspec.name, gemspec] }
    end

    # @return [void]
    def generate
      @pins = []
      @uncached_gemspecs = []
      required_gem_map.each do |path, gemspec|
        if gemspec
          try_cache gemspec
        else
          try_stdlib_map path
        end
      end
    end

    # @param gemspec [Gem::Specification]
    # @return [void]
    def try_cache gemspec
      return if try_gem_in_memory(gemspec)
      cache_file = File.join('gems', "#{gemspec.name}-#{gemspec.version}.ser")
      if Cache.exist?(cache_file)
        gempins = Cache.load(cache_file)
        self.class.gems_in_memory[gemspec] = gempins
        @pins.concat gempins
      else
        Solargraph.logger.debug "No pin cache for #{gemspec.name} #{gemspec.version}"
        @uncached_gemspecs.push gemspec
      end
    end

    # @param path [String] require path that might be in the RBS stdlib collection
    # @return [void]
    def try_stdlib_map path
      map = RbsMap::StdlibMap.load(path)
      if map.resolved?
        Solargraph.logger.debug "Loading stdlib pins for #{path}"
        @pins.concat map.pins
      else
        Solargraph.logger.warn "Require path #{path} could not be resolved"
      end
    end

    # @param gemspec [Gem::Specification]
    # @return [Boolean]
    def try_gem_in_memory gemspec
      gempins = DocMap.gems_in_memory[gemspec]
      return false unless gempins
      Solargraph.logger.debug "Found #{gemspec.name} #{gemspec.version} in memory"
      @pins.concat gempins
      true
    end

    # @param path [String]
    # @return [Gem::Specification, nil]
    def resolve_path_to_gemspec path
      gemspec = Gem::Specification.find_by_path(path)
      if gemspec.nil?
        gem_name_guess = path.split('/').first
        begin
          # this can happen when the gem is included via a local path in
          # a Gemfile; Gem doesn't try to index the paths in that case.
          #
          # See if we can make a good guess:
          potential_gemspec = Gem::Specification.find_by_name(gem_name_guess)
          file = "lib/#{path}.rb"
          gemspec = potential_gemspec if potential_gemspec.files.any? { |gemspec_file| file == gemspec_file }
        rescue Gem::MissingSpecError
          Solargraph.logger.debug "Require path #{path} could not be resolved to a gem via find_by_path or guess of #{gem_name_guess}"
          nil
        end
      end
      return gemspec if dependencies.empty? || gemspec.nil?

      if dependency_map.key?(gemspec.name)
        return gemspec if gemspec.version == dependency_map[gemspec.name].version

        change_gemspec_version gemspec, dependency_map[by_path.name].version
      else
        Solargraph.logger.warn "Gem #{gemspec.name} is not an expected dependency"
        gemspec
      end
    end

    # @param gemspec [Gem::Specification]
    # @param version [Gem::Version]
    # @return [Gem::Specification]
    def change_gemspec_version gemspec, version
      Gem::Specification.find_by_name(gemspec.name, "= #{version}")
    rescue Gem::MissingSpecError
      Solargraph.logger.info "Gem #{gemspec.name} version #{version} not found. Using #{gemspec.version} instead"
      gemspec
    end
  end
end
