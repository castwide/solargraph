# frozen_string_literal: true

require 'open3'
require 'json'
require 'yaml'

module Solargraph
  # A workspace consists of the files in a project's directory and the
  # project's configuration. It provides a Source for each file to be used
  # in an associated Library or ApiMap.
  #
  class Workspace
    include Logging

    autoload :Config, 'solargraph/workspace/config'

    # @return [String]
    attr_reader :directory

    attr_reader :preferences

    # The require paths associated with the workspace.
    #
    # @return [Array<String>]
    attr_reader :require_paths

    # @return [Array<String>]
    attr_reader :gemnames
    alias source_gems gemnames

    # @param directory [String]
    # @param config [Config, nil]
    # @param server [Hash]
    def initialize directory = '', config = nil, server = {}
      @directory = directory
      @config = config
      @server = server
      load_sources
      @gemnames = []
      @require_paths = generate_require_paths
      require_plugins
      # @todo implement preferences
      @preferences = []
    end

    # @return [Solargraph::Workspace::Config]
    def config
      @config ||= Solargraph::Workspace::Config.new(directory)
    end

    # @return [Solargraph::PinCache]
    def pin_cache
      @pin_cache ||= fresh_pincache
    end

    # @return [Environ]
    def global_environ
      # empty docmap, since the result needs to work in any possible
      # context here
      @environ ||= Convention.for_global(DocMap.new([], self))
    end

    # @param gemspec [Gem::Specification, Bundler::LazySpecification]
    # @param out [IO, nil] output stream for logging
    # @param rebuild [Boolean] whether to rebuild the pins even if they are cached
    #
    # @return [void]
    def cache_gem(gemspec, out: nil, rebuild: false)
      pin_cache.cache_gem(gemspec: gemspec, out: out, rebuild: rebuild)
    end

    # @param gemspec [Gem::Specification, Bundler::LazySpecification]
    # @param out [IO, nil] output stream for logging
    #
    # @return [void]
    def uncache_gem(gemspec, out: nil)
      pin_cache.uncache_gem(gemspec, out: out)
    end

    # @return [Solargraph::PinCache]
    def fresh_pincache
      PinCache.new(rbs_collection_path: rbs_collection_path,
                   rbs_collection_config_path: rbs_collection_config_path,
                   yard_plugins: yard_plugins,
                   directory: directory)
    end

    # @return [Array<String>]
    def yard_plugins
      @yard_plugins ||= global_environ.yard_plugins.sort.uniq
    end

    # @param path [String]
    # @return [::Array<Gem::Specification>, nil]
    def resolve_path_to_gemspecs path
      return nil if path.empty?
      # TODO: there should be a distinction between everything and the non-require: false stuff
      return gemspecs_required_from_bundler if path == 'bundler/require'

      gemspecs = gemspecs_required_from_bundler
      # @type [Gem::Specification, nil]
      gemspec = gemspecs.find { |gemspec| gemspec.name == path }
      if gemspec.nil?
        gem_name_guess = path.split('/').first
        begin
          # this can happen when the gem is included via a local path in
          # a Gemfile; Gem doesn't try to index the paths in that case.
          #
          # See if we can make a good guess:
          potential_gemspec = gemspecs.find { |gemspec| gemspec.name == gem_name_guess }

          return nil if potential_gemspec.nil?

          file = "lib/#{path}.rb"
          # @sg-ignore Unresolved call to files
          gemspec = potential_gemspec if potential_gemspec&.files&.any? { |gemspec_file| file == gemspec_file }
        rescue Gem::MissingSpecError
          logger.debug { "Require path #{path} could not be resolved to a gem via find_by_path or guess of #{gem_name_guess}" }
          []
        end
      end
      return nil if gemspec.nil?
      [gemspec_or_preference(gemspec)]
    end

    # @param gemspec [Gem::Specification]
    # @return [Array<Gem::Specification>]
    def fetch_dependencies gemspec
      gemspecs = gemspecs_required_from_bundler

      # @param spec [Gem::Dependency]
      only_runtime_dependencies(gemspec).each_with_object(Set.new) do |spec, deps|
        Solargraph.logger.info "Adding #{spec.name} dependency for #{gemspec.name}"
        # @type [Gem::Specification, nil]
        dep = gemspecs.find { |dep| dep.name == spec.name }
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
      gemspec.dependencies - gemspec.development_dependencies
    end

    # Merge the source. A merge will update the existing source for the file
    # or add it to the sources if the workspace is configured to include it.
    # The source is ignored if the configuration excludes it.
    #
    # @param sources [Array<Solargraph::Source>]
    # @return [Boolean] True if the source was added to the workspace
    def merge *sources
      unless directory == '*' || sources.all? { |source| source_hash.key?(source.filename) }
        # Reload the config to determine if a new source should be included
        @config = Solargraph::Workspace::Config.new(directory)
      end

      includes_any = false
      sources.each do |source|
        if directory == "*" || config.calculated.include?(source.filename)
          source_hash[source.filename] = source
          includes_any = true
        end
      end

      includes_any
    end

    # Remove a source from the workspace. The source will not be removed if
    # its file exists and the workspace is configured to include it.
    #
    # @param filename [String]
    # @return [Boolean] True if the source was removed from the workspace
    def remove filename
      return false unless source_hash.key?(filename)
      source_hash.delete filename
      true
    end

    # @return [Array<String>]
    def filenames
      source_hash.keys
    end

    # @return [Array<Solargraph::Source>]
    def sources
      source_hash.values
    end

    # @param filename [String]
    # @return [Boolean]
    def has_file? filename
      source_hash.key?(filename)
    end

    # Get a source by its filename.
    #
    # @param filename [String]
    # @return [Solargraph::Source]
    def source filename
      source_hash[filename]
    end

    # True if the path resolves to a file in the workspace's require paths.
    #
    # @param path [String]
    # @return [Boolean]
    def would_require? path
      require_paths.each do |rp|
        full = File.join rp, path
        return true if File.file?(full) || File.file?(full << ".rb")
      end
      false
    end

    # True if the workspace contains at least one gemspec file.
    #
    # @return [Boolean]
    def gemspec?
      !gemspecs.empty?
    end

    # Get an array of all gemspec files in the workspace.
    #
    # @return [Array<String>]
    def gemspecs
      return [] if directory.empty? || directory == '*'
      @gemspecs ||= Dir[File.join(directory, '**/*.gemspec')].select do |gs|
        config.allow? gs
      end
    end

    # @return [String, nil]
    def rbs_collection_path
      @gem_rbs_collection ||= read_rbs_collection_path
    end

    # @return [String, nil]
    # @sg-ignore Solargraph::Workspace#rbs_collection_config_path return type could not be inferred
    def rbs_collection_config_path
      @rbs_collection_config_path ||=
        begin
          unless directory.empty? || directory == '*'
            yaml_file = File.join(directory, 'rbs_collection.yaml')
            yaml_file if File.file?(yaml_file)
          end
        end
    end

    # @param out [IO, nil] output stream for logging
    # @param rebuild [Boolean] whether to rebuild the pins even if they are cached
    # @return [void]
    def cache_all_for_workspace!(out, rebuild: false)
      PinCache.cache_core(out: $stdout) unless PinCache.has_core?
      # @type [Array<Gem::Specification>]
      specs = gemspecs_required_from_bundler
      specs.each do |spec|
        unless pin_cache.cached?(spec)
          pin_cache.cache_gem(gemspec: spec, rebuild: rebuild, out: out)
        end
      end
      out.puts "Documentation cached for all #{specs.length} gems."
    end

    # Synchronize the workspace from the provided updater.
    #
    # @param updater [Source::Updater]
    # @return [void]
    def synchronize! updater
      source_hash[updater.filename] = source_hash[updater.filename].synchronize(updater)
    end

    # @return [String]
    def command_path
      server['commandPath'] || 'solargraph'
    end

    private

    # True if the workspace has a root Gemfile.
    #
    # @todo Handle projects with custom Bundler/Gemfile setups (see DocMap#gemspecs_required_from_bundler)
    #
    def gemfile?
      directory && File.file?(File.join(directory, 'Gemfile'))
    end

    # @return [Array<Gem::Specification>]
    def gemspecs_required_from_bundler
      @gemspecs_required_from_bundler ||=
        begin
          if directory && Bundler.definition&.lockfile&.to_s&.start_with?(directory) # rubocop:disable Style/SafeNavigationChainLength
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
    end

    # @return [Array<Gem::Specification>]
    def gemspecs_required_from_external_bundle
      return [] unless directory

      @gemspecs_required_from_external_bundle ||=
        begin
          logger.info 'Fetching gemspecs required from external bundle'

          Solargraph.with_clean_env do
            cmd = [
              'ruby', '-e',
              "require 'bundler'; require 'json'; Dir.chdir('#{directory}') { puts Bundler.definition.locked_gems.specs.map { |spec| [spec.name, spec.version] }.to_h.to_json }"
            ]
            # @sg-ignore Unresolved call to capture3
            o, e, s = Open3.capture3(*cmd)
            if s.success?
              Solargraph.logger.debug "External bundle: #{o}"
              hash = o && !o.empty? ? JSON.parse(o.split("\n").last) : {}
              hash.flat_map do |name, version|
                Gem::Specification.find_by_name(name, version)
              rescue Gem::MissingSpecError => e
                logger.info("Could not find #{name}:#{version} with find_by_name, falling back to guess")
                # can happen in local filesystem references
                specs = Gem::Specification.find_by_path(name)
                specs ||= Gem::Specification.find_by_name(name)
                logger.warn "Gem #{name} #{version} from bundle not found: #{e}" if specs.nil?
                next specs
              end.compact
            else
              Solargraph.logger.warn e
              raise BundleNotFoundError, "Failed to load gems from bundle at #{directory}"
            end
          end
        end
    end

    # @return [Hash{String => Gem::Specification}]
    def preference_map
      @preference_map ||= preferences.to_h { |gemspec| [gemspec.name, gemspec] }
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

    # The language server configuration (or an empty hash if the workspace was
    # not initialized from a server).
    #
    # @return [Hash]
    attr_reader :server

    # @return [Hash{String => Solargraph::Source}]
    def source_hash
      @source_hash ||= {}
    end

    # @return [void]
    def load_sources
      source_hash.clear
      unless directory.empty? || directory == '*'
        size = config.calculated.length
        raise WorkspaceTooLargeError, "The workspace is too large to index (#{size} files, #{config.max_files} max)" if config.max_files > 0 and size > config.max_files
        config.calculated.each do |filename|
          begin
            source_hash[filename] = Solargraph::Source.load(filename)
          rescue Errno::ENOENT => e
            Solargraph.logger.warn("Error loading #{filename}: [#{e.class}] #{e.message}")
          end
        end
      end
    end

    # Generate require paths from gemspecs if they exist or assume the default
    # lib directory.
    #
    # @return [Array<String>]
    def generate_require_paths
      return configured_require_paths unless gemspec?
      result = []
      gemspecs.each do |file|
        base = File.dirname(file)
        # HACK: Evaluating gemspec files violates the goal of not running
        #   workspace code, but this is how Gem::Specification.load does it
        #   anyway.
        cmd = ['ruby', '-e', "require 'rubygems'; require 'json'; spec = eval(File.read('#{file}'), TOPLEVEL_BINDING, '#{file}'); return unless Gem::Specification === spec; puts({name: spec.name, paths: spec.require_paths}.to_json)"]
        # @sg-ignore Unresolved call to capture3
        o, e, s = Open3.capture3(*cmd)
        if s.success?
          begin
            hash = o && !o.empty? ? JSON.parse(o.split("\n").last) : {}
            next if hash.empty?
            @gemnames.push hash['name']
            result.concat(hash['paths'].map { |path| File.join(base, path) })
          rescue StandardError => e
            Solargraph.logger.warn "Error reading #{file}: [#{e.class}] #{e.message}"
          end
        else
          Solargraph.logger.warn "Error reading #{file}"
          Solargraph.logger.warn e
        end
      end
      result.concat(config.require_paths.map { |p| File.join(directory, p) })
      result.push File.join(directory, 'lib') if result.empty?
      result
    end

    # Get additional require paths defined in the configuration.
    #
    # @return [Array<String>]
    def configured_require_paths
      return ['lib'] if directory.empty?
      return [File.join(directory, 'lib')] if config.require_paths.empty?
      config.require_paths.map { |p| File.join(directory, p) }
    end

    # @return [void]
    def require_plugins
      config.plugins.each do |plugin|
        begin
          require plugin
        rescue LoadError
          Solargraph.logger.warn "Failed to load plugin '#{plugin}'"
        end
      end
    end

    # @return [String, nil]
    def read_rbs_collection_path
      return unless rbs_collection_config_path

      # @sg-ignore Unresolved call to load_file
      path = YAML.load_file(rbs_collection_config_path)&.fetch('path')
      # make fully qualified
      File.expand_path(path, directory)
    end
  end
end
