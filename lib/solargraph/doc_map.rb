# frozen_string_literal: true

module Solargraph
  # A collection of pins generated from required gems.
  #
  class DocMap
    include Logging

    # @return [Array<String>]
    attr_reader :requires
    alias required requires

    # @return [Array<Gem::Specification>]
    attr_reader :preferences

    # @return [Array<Pin::Base>]
    attr_reader :pins

    # @return [Array<Gem::Specification>]
    attr_reader :uncached_gemspecs

    # @return [Workspace, nil]
    attr_reader :workspace

    # @return [Environ]
    attr_reader :environ

    # @param requires [Array<String>]
    # @param preferences [Array<Gem::Specification>]
    # @param workspace [Workspace, nil]
    def initialize(requires, preferences, workspace = nil)
      @requires = requires.compact
      @preferences = preferences.compact
      @workspace = workspace
      @rbs_path = workspace&.rbs_collection_path
      @environ = Convention.for_global(self)
      generate_gem_pins
      pins.concat @environ.pins
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
    def generate_gem_pins
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
      return gempins unless workspace&.rbs_collection_path && File.directory?(workspace&.rbs_collection_path)
      return gempins if RbsMap.new(gemspec.name, gemspec.version).resolved?

      rbs_map = RbsMap.new(gemspec.name, gemspec.version, directories: [workspace&.rbs_collection_path])
      return gempins unless rbs_map.resolved?

      Solargraph.logger.info "Updating #{gemspec.name} #{gemspec.version} from collection"
      GemPins.combine(gempins, rbs_map)
    end

    # @param path [String]
    # @return [::Array<Gem::Specification>, nil]
    def resolve_path_to_gemspecs path
      return nil if path.empty?
      return gemspecs_required_from_bundler if path == 'bundler/require'

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
        dep = Gem.loaded_specs[spec.name]
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

    def gemspecs_required_from_bundler
      if workspace&.directory && Bundler.definition&.lockfile&.to_s&.start_with?(workspace.directory)
        # Find only the gems bundler is now using
        Bundler.definition.locked_gems.specs.flat_map do |lazy_spec|
          logger.info "Handling #{lazy_spec.name}:#{lazy_spec.version}"
          [Gem::Specification.find_by_name(lazy_spec.name, lazy_spec.version)]
        rescue Gem::MissingSpecError => e
          logger.info("Could not find #{lazy_spec.name}:#{lazy_spec.version} with find_by_name, falling back to guess")
          # can happen in local filesystem references
          specs = resolve_path_to_gemspecs lazy_spec.name
          logger.info "Gem #{lazy_spec.name} #{lazy_spec.version} from bundle not found: #{e}" if specs.nil?
          next specs
        end.compact
      else
        logger.info 'Fetching gemspecs required from Bundler (bundler/require)'
        gemspecs_required_from_external_bundle
      end
    end

    def gemspecs_required_from_external_bundle
      logger.info 'Fetching gemspecs required from external bundle'
      return [] unless workspace&.directory

      Solargraph.with_clean_env do
        cmd = [
          'ruby', '-e',
          "require 'bundler'; require 'json'; Dir.chdir('#{workspace&.directory}') { puts Bundler.definition.locked_gems.specs.map { |spec| [spec.name, spec.version] }.to_h.to_json }"
        ]
        o, e, s = Open3.capture3(*cmd)
        if s.success?
          Solargraph.logger.debug "External bundle: #{o}"
          hash = o && !o.empty? ? JSON.parse(o.split("\n").last) : {}
          hash.map do |name, version|
            Gem::Specification.find_by_name(name, version)
          rescue Gem::MissingSpecError => e
            logger.info("Could not find #{name}:#{version} with find_by_name, falling back to guess")
            # can happen in local filesystem references
            specs = resolve_path_to_gemspecs name
            logger.info "Gem #{name} #{version} from bundle not found: #{e}" if specs.nil?
            next specs
          end.compact
        else
          Solargraph.logger.warn e
          raise BundleNotFoundError, "Failed to load gems from bundle at #{workspace&.directory}"
        end
      end
    end
  end
end
