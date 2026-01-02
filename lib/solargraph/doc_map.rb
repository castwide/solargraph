# frozen_string_literal: true

require 'pathname'
require 'benchmark'
require 'open3'

module Solargraph
  # A collection of pins generated from specific 'require' statements
  # in code.  Multiple can be created per workspace, to represent the
  # pins available in different files based on their particular
  # 'require' lines.
  #
  class DocMap
    include Logging

    # @return [Workspace]
    attr_reader :workspace

    # @return [Array<Gem::Specification>]
    attr_reader :preferences

    # @param requires [Array<String>]
    # @param preferences [Array<Gem::Specification>]
    # @param workspace [Workspace]
    # @param out [IO, nil] output stream for logging
    def initialize requires, preferences, workspace, out: $stderr
      @provided_requires = requires.compact
      @preferences = preferences.compact
      @workspace = workspace
      @out = out
    end

    # @return [Array<String>]
    def requires
      @requires ||= @provided_requires + (workspace.global_environ&.requires || [])
    end
    alias required requires

    # @return [Array<Gem::Specification>]
    def uncached_gemspecs
      if @uncached_gemspecs.nil?
        @uncached_gemspecs = []
        pins # force lazy-loaded pin lookup
      end
      @uncached_gemspecs
    end

    # @return [Array<Pin::Base>]
    def pins
      @pins ||= load_serialized_gem_pins + (workspace.global_environ&.pins || [])
    end

    # @return [void]
    def reset_pins!
      @uncached_gemspecs = nil
      @pins = nil
    end

    # @return [Solargraph::PinCache]
    def pin_cache
      @pin_cache ||= workspace.fresh_pincache
    end

    def any_uncached?
      uncached_gemspecs.any?
    end

    # Cache all pins needed for the sources in this doc_map
    # @param out [StringIO, IO, nil] output stream for logging
    # @return [void]
    def cache_doc_map_gems! out
      unless uncached_gemspecs.empty?
        logger.info do
          gem_desc = uncached_gemspecs.map { |gemspec| "#{gemspec.name}:#{gemspec.version}" }.join(', ')
          "Caching pins for gems: #{gem_desc}"
        end
      end
      time = Benchmark.measure do
        uncached_gemspecs.each do |gemspec|
          cache(gemspec, out: out)
        end
      end
      milliseconds = (time.real * 1000).round
      if (milliseconds > 500) && uncached_gemspecs.any? && out && uncached_gemspecs.any?
        out.puts "Built #{uncached_gemspecs.length} gems in #{milliseconds} ms"
      end
      reset_pins!
    end

    # @return [Array<String>]
    def unresolved_requires
      @unresolved_requires ||= required_gems_map.select { |_, gemspecs| gemspecs.nil? }.keys
    end

    # @return [Array<Gem::Specification>]
    # @param out [IO]
    def dependencies out: $stderr
      @dependencies ||=
        begin
          all_deps = gemspecs
                       .flat_map { |spec| fetch_dependencies(spec, out: out) }
                       .uniq(&:name)
          existing_gems = gemspecs.map(&:name)
          all_deps.reject { |gemspec| existing_gems.include? gemspec.name }
        end
    end

    # Cache gem documentation if needed for this doc_map
    #
    # @param gemspec [Gem::Specification]
    # @param rebuild [Boolean] whether to rebuild the pins even if they are cached
    # @param out [StringIO, IO, nil] output stream for logging
    #
    # @return [void]
    def cache gemspec, rebuild: false, out: nil
      pin_cache.cache_gem(gemspec: gemspec,
                          rebuild: rebuild,
                          out: out)
    end

    private

    # @return [Array<Gem::Specification>]
    def gemspecs
      @gemspecs ||= required_gems_map.values.compact.flatten
    end

    # @param out [IO, nil]
    # @return [Array<Pin::Base>]
    def load_serialized_gem_pins out: @out
      serialized_pins = []
      with_gemspecs, without_gemspecs = required_gems_map.partition { |_, v| v }
      # @sg-ignore Need support for RBS duck interfaces like _ToHash
      # @type [Array<String>]
      missing_paths = Hash[without_gemspecs].keys
      # @sg-ignore Need support for RBS duck interfaces like _ToHash
      # @type [Array<Gem::Specification>]
      gemspecs = Hash[with_gemspecs].values.flatten.compact + dependencies(out: out).to_a

      missing_paths.each do |path|
        # this will load from disk if needed; no need to manage
        # uncached_gemspecs to trigger that later
        stdlib_name_guess = path.split('/').first

        # try to resolve the stdlib name
        deps = workspace.stdlib_dependencies(stdlib_name_guess) || []
        [stdlib_name_guess, *deps].compact.each do |potential_stdlib_name|
          rbs_pins = pin_cache.cache_stdlib_rbs_map potential_stdlib_name
          serialized_pins.concat rbs_pins if rbs_pins
        end
      end

      existing_pin_count = serialized_pins.length
      time = Benchmark.measure do
        gemspecs.each do |gemspec|
          # only deserializes already-cached gems
          gemspec_pins = pin_cache.deserialize_combined_pin_cache gemspec
          if gemspec_pins
            serialized_pins.concat gemspec_pins
          else
            uncached_gemspecs << gemspec
          end
        end
      end
      pins_processed = serialized_pins.length - existing_pin_count
      milliseconds = (time.real * 1000).round
      if (milliseconds > 500) && out && gemspecs.any?
        out.puts "Deserialized #{serialized_pins.length} gem pins from #{PinCache.base_dir} in #{milliseconds} ms"
      end
      uncached_gemspecs.uniq! { |gemspec| "#{gemspec.name}:#{gemspec.version}" }
      serialized_pins
    end

    # @return [Hash{String => Array<Gem::Specification>}]
    def required_gems_map
      @required_gems_map ||= requires.to_h { |path| [path, resolve_path_to_gemspecs(path)] }
    end

    # @return [Hash{String => Gem::Specification}]
    def preference_map
      @preference_map ||= preferences.to_h { |gemspec| [gemspec.name, gemspec] }
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
    # @param version [Gem::Version]
    # @return [Gem::Specification]
    def change_gemspec_version gemspec, version
      Gem::Specification.find_by_name(gemspec.name, "= #{version}")
    rescue Gem::MissingSpecError
      Solargraph.logger.info "Gem #{gemspec.name} version #{version} not found. Using #{gemspec.version} instead"
      gemspec
    end

    # @param gemspec [Gem::Specification]
    # @param out [IO, nil]
    #
    # @return [Array<Gem::Specification>]
    def fetch_dependencies gemspec, out: nil
      # @param spec [Gem::Dependency]
      # @param deps [Set<Gem::Specification>]
      only_runtime_dependencies(gemspec).each_with_object(Set.new) do |spec, deps|
        Solargraph.logger.info "Adding #{spec.name} dependency for #{gemspec.name}"
        dep = Gem.loaded_specs[spec.name]
        # @todo is next line necessary?
        dep ||= Gem::Specification.find_by_name(spec.name, spec.requirement)
        deps.merge fetch_dependencies(dep) if deps.add?(dep)
      rescue Gem::MissingSpecError
        Solargraph.logger.warn "Gem dependency #{spec.name} #{spec.requirement} for #{gemspec.name} not found in RubyGems."
      end.to_a
    end

    # @param gemspec [Gem::Specification]
    # @return [Array<Gem::Dependency>]
    def only_runtime_dependencies gemspec
      gemspec_deps = gemspec.dependencies - gemspec.development_dependencies
      stdlib_dep_names = workspace.stdlib_dependencies(gemspec.name)
      stdlib_deps = workspace.stdlib_dependencies(gemspec.name).flat_map do |dep_name|
        # already know about this dependency
        next [] if gemspec_deps.any? { |dep| dep.name == dep_name }

        stdlib_specs = resolve_path_to_gemspecs(dep_name) || []

        stdlib_specs.map { |spec| Gem::Dependency.new spec.name, "= #{spec.version}" }
      end
      gemspec_deps + stdlib_deps
    end

    def inspect
      self.class.inspect
    end

    # @return [Array<Gem::Specification>, nil]
    def gemspecs_required_from_bundler
      # @todo Handle projects with custom Bundler/Gemfile setups
      return unless workspace.gemfile?

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
        end
      end
    end
  end
end
