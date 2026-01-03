# frozen_string_literal: true

require 'pathname'
require 'benchmark'
require 'open3'

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
    def uncached_gemspecs
      uncached_yard_gemspecs.concat(uncached_rbs_collection_gemspecs)
                            .sort
                            .uniq { |gemspec| "#{gemspec.name}:#{gemspec.version}" }
    end

    # @return [Array<Gem::Specification>]
    attr_reader :uncached_yard_gemspecs

    # @return [Array<Gem::Specification>]
    attr_reader :uncached_rbs_collection_gemspecs

    # @return [String, nil]
    attr_reader :rbs_collection_path

    # @return [String, nil]
    attr_reader :rbs_collection_config_path

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
      @rbs_collection_path = workspace&.rbs_collection_path
      @rbs_collection_config_path = workspace&.rbs_collection_config_path
      @environ = Convention.for_global(self)
      @requires.concat @environ.requires if @environ
      load_serialized_gem_pins
      pins.concat @environ.pins
    end

    # @param out [StringIO, IO, nil]
    # @return [void]
    def cache_all!(out)
      # if we log at debug level:
      if logger.info?
        gem_desc = uncached_gemspecs.map { |gemspec| "#{gemspec.name}:#{gemspec.version}" }.join(', ')
        logger.info "Caching pins for gems: #{gem_desc}" unless uncached_gemspecs.empty?
      end
      logger.debug { "Caching for YARD: #{uncached_yard_gemspecs.map(&:name)}" }
      logger.debug { "Caching for RBS collection: #{uncached_rbs_collection_gemspecs.map(&:name)}" }
      load_serialized_gem_pins
      uncached_gemspecs.each do |gemspec|
        cache(gemspec, out: out)
      end
      load_serialized_gem_pins
      @uncached_rbs_collection_gemspecs = []
      @uncached_yard_gemspecs = []
    end

    # @param gemspec [Gem::Specification]
    # @param out [StringIO, IO, nil]
    # @return [void]
    def cache_yard_pins(gemspec, out)
      pins = GemPins.build_yard_pins(yard_plugins, gemspec)
      PinCache.serialize_yard_gem(gemspec, pins)
      logger.info { "Cached #{pins.length} YARD pins for gem #{gemspec.name}:#{gemspec.version}" } unless pins.empty?
    end

    # @param gemspec [Gem::Specification]
    # @param out [StringIO, IO, nil]
    # @return [void]
    def cache_rbs_collection_pins(gemspec, out)
      rbs_map = RbsMap.from_gemspec(gemspec, rbs_collection_path, rbs_collection_config_path)
      pins = rbs_map.pins
      rbs_version_cache_key = rbs_map.cache_key
      # cache pins even if result is zero, so we don't retry building pins
      pins ||= []
      PinCache.serialize_rbs_collection_gem(gemspec, rbs_version_cache_key, pins)
      logger.info { "Cached #{pins.length} RBS collection pins for gem #{gemspec.name} #{gemspec.version} with cache_key #{rbs_version_cache_key.inspect}" unless pins.empty? }
    end

    # @param gemspec [Gem::Specification]
    # @param rebuild [Boolean] whether to rebuild the pins even if they are cached
    # @param out [StringIO, IO, nil] output stream for logging
    # @return [void]
    def cache(gemspec, rebuild: false, out: nil)
      build_yard = uncached_yard_gemspecs.include?(gemspec) || rebuild
      build_rbs_collection = uncached_rbs_collection_gemspecs.include?(gemspec) || rebuild
      if build_yard || build_rbs_collection
        type = []
        type << 'YARD' if build_yard
        type << 'RBS collection' if build_rbs_collection
        out.puts("Caching #{type.join(' and ')} pins for gem #{gemspec.name}:#{gemspec.version}") if out
      end
      cache_yard_pins(gemspec, out) if build_yard
      cache_rbs_collection_pins(gemspec, out) if build_rbs_collection
    end

    # @return [Array<Gem::Specification>]
    def gemspecs
      @gemspecs ||= required_gems_map.values.compact.flatten
    end

    # @return [Array<String>]
    def unresolved_requires
      @unresolved_requires ||= required_gems_map.select { |_, gemspecs| gemspecs.nil? }.keys
    end

    # @return [Hash{Array(String, String) => Array<Pin::Base>}] Indexed by gemspec name and version
    def self.all_yard_gems_in_memory
      @yard_gems_in_memory ||= {}
    end

    # @return [Hash{String => Hash{Array(String, String) => Array<Pin::Base>}}] stored by RBS collection path
    def self.all_rbs_collection_gems_in_memory
      @rbs_collection_gems_in_memory ||= {}
    end

    # @return [Hash{Array(String, String) => Array<Pin::Base>}] Indexed by gemspec name and version
    def yard_pins_in_memory
      self.class.all_yard_gems_in_memory
    end

    # @return [Hash{Array(String, String) => Array<Pin::Base>}] Indexed by gemspec name and version
    def rbs_collection_pins_in_memory
      # @sg-ignore Need to add nil check here
      self.class.all_rbs_collection_gems_in_memory[rbs_collection_path] ||= {}
    end

    # @return [Hash{Array(String, String) => Array<Pin::Base>}] Indexed by gemspec name and version
    def self.all_combined_pins_in_memory
      @combined_pins_in_memory ||= {}
    end

    # @todo this should also include an index by the hash of the RBS collection
    # @return [Hash{Array(String, String) => Array<Pin::Base>}] Indexed by gemspec name and version
    def combined_pins_in_memory
      self.class.all_combined_pins_in_memory
    end

    # @return [Array<String>]
    def yard_plugins
      @environ.yard_plugins
    end

    # @return [Set<Gem::Specification>]
    def dependencies
      @dependencies ||= (gemspecs.flat_map { |spec| fetch_dependencies(spec) } - gemspecs).to_set
    end

    private

    # @return [void]
    def load_serialized_gem_pins
      @pins = []
      @uncached_yard_gemspecs = []
      @uncached_rbs_collection_gemspecs = []
      with_gemspecs, without_gemspecs = required_gems_map.partition { |_, v| v }
      # @sg-ignore Need better typing for Hash[]
      # @type [Array<String>]
      paths = Hash[without_gemspecs].keys
      # @type [Array<Gem::Specification>]
      gemspecs = Hash[with_gemspecs].values.flatten.compact + dependencies.to_a

      paths.each do |path|
        rbs_pins = deserialize_stdlib_rbs_map path
      end

      logger.debug { "DocMap#load_serialized_gem_pins: Combining pins..." }
      time = Benchmark.measure do
        gemspecs.each do |gemspec|
          pins = deserialize_combined_pin_cache gemspec
          @pins.concat pins if pins
        end
      end
      logger.info { "DocMap#load_serialized_gem_pins: Loaded and processed serialized pins together in #{time.real} seconds" }
      @uncached_yard_gemspecs.uniq!
      @uncached_rbs_collection_gemspecs.uniq!
      nil
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
    # @return [Array<Pin::Base>, nil]
    def deserialize_yard_pin_cache gemspec
      if yard_pins_in_memory.key?([gemspec.name, gemspec.version])
        return yard_pins_in_memory[[gemspec.name, gemspec.version]]
      end

      cached = PinCache.deserialize_yard_gem(gemspec)
      if cached
        logger.info { "Loaded #{cached.length} cached YARD pins from #{gemspec.name}:#{gemspec.version}" }
        yard_pins_in_memory[[gemspec.name, gemspec.version]] = cached
        cached
      else
        logger.debug "No YARD pin cache for #{gemspec.name}:#{gemspec.version}"
        @uncached_yard_gemspecs.push gemspec
        nil
      end
    end

    # @param gemspec [Gem::Specification]
    # @return [void]
    def deserialize_combined_pin_cache(gemspec)
      unless combined_pins_in_memory[[gemspec.name, gemspec.version]].nil?
        return combined_pins_in_memory[[gemspec.name, gemspec.version]]
      end

      rbs_map = RbsMap.from_gemspec(gemspec, rbs_collection_path, rbs_collection_config_path)
      rbs_version_cache_key = rbs_map.cache_key

      cached = PinCache.deserialize_combined_gem(gemspec, rbs_version_cache_key)
      if cached
        logger.info { "Loaded #{cached.length} cached YARD pins from #{gemspec.name}:#{gemspec.version}" }
        combined_pins_in_memory[[gemspec.name, gemspec.version]] = cached
        return combined_pins_in_memory[[gemspec.name, gemspec.version]]
      end

      rbs_collection_pins = deserialize_rbs_collection_cache gemspec, rbs_version_cache_key

      yard_pins = deserialize_yard_pin_cache gemspec

      if !rbs_collection_pins.nil? && !yard_pins.nil?
        logger.debug { "Combining pins for #{gemspec.name}:#{gemspec.version}" }
        combined_pins = GemPins.combine(yard_pins, rbs_collection_pins)
        PinCache.serialize_combined_gem(gemspec, rbs_version_cache_key, combined_pins)
        combined_pins_in_memory[[gemspec.name, gemspec.version]] = combined_pins
        logger.info { "Generated #{combined_pins_in_memory[[gemspec.name, gemspec.version]].length} combined pins for #{gemspec.name} #{gemspec.version}" }
        return combined_pins
      end

      if !yard_pins.nil?
        logger.debug { "Using only YARD pins for #{gemspec.name}:#{gemspec.version}" }
        combined_pins_in_memory[[gemspec.name, gemspec.version]] = yard_pins
        return combined_pins_in_memory[[gemspec.name, gemspec.version]]
      elsif !rbs_collection_pins.nil?
        logger.debug { "Using only RBS collection pins for #{gemspec.name}:#{gemspec.version}" }
        combined_pins_in_memory[[gemspec.name, gemspec.version]] = rbs_collection_pins
        return combined_pins_in_memory[[gemspec.name, gemspec.version]]
      else
        logger.debug { "Pins not yet cached for #{gemspec.name}:#{gemspec.version}" }
        return nil
      end
    end

    # @param path [String] require path that might be in the RBS stdlib collection
    # @return [void]
    def deserialize_stdlib_rbs_map path
      map = RbsMap::StdlibMap.load(path)
      if map.resolved?
        logger.debug { "Loading stdlib pins for #{path}" }
        @pins.concat map.pins
        logger.debug { "Loaded #{map.pins.length} stdlib pins for #{path}" }
        map.pins
      else
        # @todo Temporarily ignoring unresolved `require 'set'`
        logger.debug { "Require path #{path} could not be resolved in RBS" } unless path == 'set'
        nil
      end
    end

    # @param gemspec [Gem::Specification]
    # @param rbs_version_cache_key [String]
    # @return [Array<Pin::Base>, nil]
    def deserialize_rbs_collection_cache gemspec, rbs_version_cache_key
      return if rbs_collection_pins_in_memory.key?([gemspec, rbs_version_cache_key])
      cached = PinCache.deserialize_rbs_collection_gem(gemspec, rbs_version_cache_key)
      if cached
        logger.info { "Loaded #{cached.length} pins from RBS collection cache for #{gemspec.name}:#{gemspec.version}" } unless cached.empty?
        rbs_collection_pins_in_memory[[gemspec, rbs_version_cache_key]] = cached
        cached
      else
        logger.debug "No RBS collection pin cache for #{gemspec.name} #{gemspec.version}"
        @uncached_rbs_collection_gemspecs.push gemspec
        nil
      end
    end

    # @param path [String]
    # @return [::Array<Gem::Specification>, nil]
    def resolve_path_to_gemspecs path
      return nil if path.empty?
      return gemspecs_required_from_bundler if path == 'bundler/require'

      # @type [Gem::Specification, nil]
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
          logger.debug { "Require path #{path} could not be resolved to a gem via find_by_path or guess of #{gem_name_guess}" }
          []
        end
      end
      return nil if gemspec.nil?
      [gemspec_or_preference(gemspec)]
    end

    # @param gemspec [Gem::Specification]
    # @return [Gem::Specification]
    def gemspec_or_preference gemspec
      # :nocov: dormant feature
      return gemspec unless preference_map.key?(gemspec.name)
      return gemspec if gemspec.version == preference_map[gemspec.name].version

      change_gemspec_version gemspec, preference_map[gemspec.name].version
      # :nocov:
    end

    # @param gemspec [Gem::Specification]
    # @param version [Gem::Version, String]
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
      # @param deps [Set<Gem::Specification>]
      only_runtime_dependencies(gemspec).each_with_object(Set.new) do |spec, deps|
        Solargraph.logger.info "Adding #{spec.name} dependency for #{gemspec.name}"
        dep = Gem.loaded_specs[spec.name]
        # @todo is next line necessary?
        # @sg-ignore Unresolved call to requirement on Gem::Dependency
        dep ||= Gem::Specification.find_by_name(spec.name, spec.requirement)
        deps.merge fetch_dependencies(dep) if deps.add?(dep)
      rescue Gem::MissingSpecError
        # @sg-ignore Unresolved call to requirement on Gem::Dependency
        Solargraph.logger.warn "Gem dependency #{spec.name} #{spec.requirement} for #{gemspec.name} not found in RubyGems."
      end.to_a
    end

    # @param gemspec [Gem::Specification]
    # @return [Array<Gem::Dependency>]
    def only_runtime_dependencies gemspec
      gemspec.dependencies - gemspec.development_dependencies
    end


    def inspect
      self.class.inspect
    end

    # @return [Array<Gem::Specification>, nil]
    def gemspecs_required_from_bundler
      # @todo Handle projects with custom Bundler/Gemfile setups
      # @sg-ignore Need to add nil check here
      return unless workspace.gemfile?

      # @todo: redundant check
      # @sg-ignore Need to add nil check here
      if workspace.gemfile? && Bundler.definition&.lockfile&.to_s&.start_with?(workspace.directory)
        # Find only the gems bundler is now using
        Bundler.definition.locked_gems.specs.flat_map do |lazy_spec|
          logger.info "Handling #{lazy_spec.name}:#{lazy_spec.version}"
          [Gem::Specification.find_by_name(lazy_spec.name, lazy_spec.version)]
        rescue Gem::MissingSpecError => e
          logger.info("Could not find #{lazy_spec.name}:#{lazy_spec.version} with find_by_name, falling back to guess")
          # can happen in local filesystem references
          specs = resolve_path_to_gemspecs lazy_spec.name
          logger.warn "Gem #{lazy_spec.name} #{lazy_spec.version} from bundle not found: #{e}" if specs.nil?
          next specs
        end.compact
      else
        logger.info 'Fetching gemspecs required from Bundler (bundler/require)'
        gemspecs_required_from_external_bundle
      end
    end

    # @return [Array<Gem::Specification>, nil]
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
          hash.flat_map do |name, version|
            Gem::Specification.find_by_name(name, version)
          rescue Gem::MissingSpecError => e
            logger.info("Could not find #{name}:#{version} with find_by_name, falling back to guess")
            # can happen in local filesystem references
            specs = resolve_path_to_gemspecs name
            logger.warn "Gem #{name} #{version} from bundle not found: #{e}" if specs.nil?
            next specs
          end.compact
        else
          Solargraph.logger.warn "Failed to load gems from bundle at #{workspace&.directory}: #{e}"
          nil
        end
      end
    end
  end
end
