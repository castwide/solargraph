# frozen_string_literal: true

module Solargraph
  # A collection of pins generated from required gems.
  #
  class DocMap
    # @return [Array<String>]
    attr_reader :requires

    # @return [Array<Gem::Specification>]
    attr_reader :preferences

    # @return [Array<Pin::Base>]
    attr_reader :pins

    # @return [Array<Gem::Specification>]
    attr_reader :uncached_gemspecs

    # @param requires [Array<String>]
    # @param preferences [Array<Gem::Specification>]
    # @param rbs_path [String, Pathname, nil]
    def initialize(requires, preferences, rbs_path = nil)
      @requires = requires.compact
      @preferences = preferences.compact
      @rbs_path = rbs_path
      generate
    end

    # @return [Array<Gem::Specification>]
    def gemspecs
      @gemspecs ||= required_gems_map.values.compact.flatten
    end

    # @return [Array<String>]
    def unresolved_requires
      @unresolved_requires ||= required_gems_map.select { |_, gemspecs| gemspecs.nil? }.keys
    end

    # @return [Hash{Gem::Specification => Array[Pin::Base]}]
    def self.gems_in_memory
      @gems_in_memory ||= {}
    end

    # @return [Set<Gem::Specification>]
    def dependencies
      @dependencies ||= (gemspecs.flat_map { |spec| fetch_dependencies(spec) } - gemspecs).to_set
    end

    private

    # @return [void]
    def generate
      @pins = []
      @uncached_gemspecs = []
      required_gems_map.each do |path, gemspecs|
        if gemspecs.nil?
          try_stdlib_map path
        else
          gemspecs.each do |gemspec|
            try_cache gemspec
          end
        end
      end
      dependencies.each { |dep| try_cache dep }
      @uncached_gemspecs.uniq!
    end

    # @return [Hash{String => Array<Gem::Specification>}]
    def required_gems_map
      @required_gems_map ||= requires.to_h { |path| [path, resolve_path_to_gemspecs(path)] }
    end

    # @return [Hash{String => Gem::Specification}]
    def preference_map
      @preference_map ||= preferences.to_h { |gemspec| [gemspec.name, gemspec] }
    end

    # @param gemspec [Gem::Specification]
    # @return [void]
    def try_cache gemspec
      return if try_gem_in_memory(gemspec)
      cache_file = File.join('gems', "#{gemspec.name}-#{gemspec.version}.ser")
      if Cache.exist?(cache_file)
        cached = Cache.load(cache_file)
        gempins = update_from_collection(gemspec, cached)
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
        # @todo Temporarily ignoring unresolved `require 'set'`
        Solargraph.logger.debug "Require path #{path} could not be resolved" unless path == 'set'
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

    # @param gemspec [Gem::Specification]
    def update_from_collection gemspec, gempins
      return gempins unless @rbs_path && File.directory?(@rbs_path)
      return gempins if RbsMap.new(gemspec.name, gemspec.version).resolved?

      rbs_map = RbsMap.new(gemspec.name, gemspec.version, directories: [@rbs_path])
      return gempins unless rbs_map.resolved?

      Solargraph.logger.info "Updating #{gemspec.name} #{gemspec.version} from collection"
      GemPins.combine(gempins, rbs_map)
    end

    # @param path [String]
    # @return [::Array<Gem::Specification>, nil]
    def resolve_path_to_gemspecs path
      return nil if path.empty?

      if path == 'bundler/require'
        return Gem.loaded_specs.values.flatten
      end

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
          []
        end
      end
      return nil if gemspec.nil?
      [gemspec_or_preference(gemspec)]
    end

    # @param gemspec [Gem::Specification]
    # @return [Gem::Specification]
    def gemspec_or_preference gemspec
      return gemspec unless preference_map.key?(gemspec.name)
      return gemspec if gemspec.version == preference_map[gemspec.name].version

      change_gemspec_version gemspec, preference_map[by_path.name].version
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

    # @param gemspec [Gem::Specification]
    # @return [Array<Gem::Specification>]
    def fetch_dependencies gemspec
      # @param spec [Gem::Dependency]
      only_runtime_dependencies(gemspec).each_with_object(Set.new) do |spec, deps|
        Solargraph.logger.info "Adding #{spec.name} dependency for #{gemspec.name}"
        dep = Gem.loaded_specs[gemspec.name]
        # @todo is next line necessary?
        dep ||= Gem::Specification.find_by_name(spec.name, spec.requirement)
        deps.merge fetch_dependencies(dep) if deps.add?(dep)
      rescue Gem::MissingSpecError
        Solargraph.logger.warn "Gem dependency #{spec.name} #{spec.requirement} for #{gemspec.name} not found."
      end.to_a
    end

    # @param gemspec [Gem::Specification]
    # @return [Array<Gem::Dependency>]
    def only_runtime_dependencies gemspec
      gemspec.dependencies - gemspec.development_dependencies
    end
  end
end
