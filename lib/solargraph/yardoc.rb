# frozen_string_literal: true

require 'open3'

module Solargraph
  # Methods for caching and loading YARD documentation for gems.
  #
  module Yardoc
    module_function

    # Build and save a gem's yardoc into a given path.
    #
    # @param gem_yardoc_path [String] the path to the yardoc cache of a particular gem
    # @param yard_plugins [Array<String>]
    # @param gemspec [Gem::Specification]
    #
    # @return [void]
    def build_docs gem_yardoc_path, yard_plugins, gemspec
      return if docs_built?(gem_yardoc_path)

      unless Dir.exist? gemspec.gem_dir
        # Can happen in at least some (old?) RubyGems versions when we
        # have a gemspec describing a standard library like bundler.
        #
        # https://github.com/apiology/solargraph/actions/runs/17650140201/job/50158676842?pr=10
        Solargraph.logger.info { "Bad info from gemspec - #{gemspec.gem_dir} does not exist" }
        return
      end

      Solargraph.logger.info "Caching yardoc for #{gemspec.name} #{gemspec.version}"
      cmd = "yardoc --db #{gem_yardoc_path} --no-output --plugin solargraph"
      yard_plugins.each { |plugin| cmd << " --plugin #{plugin}" }
      Solargraph.logger.debug { "Running: #{cmd}" }
      # @todo set these up to run in parallel
      # @sg-ignore Our fill won't work properly due to an issue in
      #   Callable#arity_matches? - see comment there
      stdout_and_stderr_str, status = Open3.capture2e(current_bundle_env_tweaks, cmd, chdir: gemspec.gem_dir)
      return if status.success?
      Solargraph.logger.warn { "YARD failed running #{cmd.inspect} in #{gemspec.gem_dir}" }
      Solargraph.logger.info stdout_and_stderr_str
    end

    # @param gem_yardoc_path [String] the path to the yardoc cache of a particular gem
    # @param gemspec [Gem::Specification, Bundler::LazySpecification]
    # @param out [StringIO, IO, nil] where to log messages
    # @return [Array<Pin::Base>]
    def build_pins gem_yardoc_path, gemspec, out: $stderr
      yardoc = load!(gem_yardoc_path)
      YardMap::Mapper.new(yardoc, gemspec).map
    end

    # True if the gem yardoc is cached.
    #
    # @param gem_yardoc_path [String]
    def docs_built? gem_yardoc_path
      yardoc = File.join(gem_yardoc_path, 'complete')
      File.exist?(yardoc)
    end

    # True if another process is currently building the yardoc cache.
    #
    # @param gem_yardoc_path [String] the path to the yardoc cache of a particular gem
    def processing? gem_yardoc_path
      yardoc = File.join(gem_yardoc_path, 'processing')
      File.exist?(yardoc)
    end

    # Load a gem's yardoc and return its code objects.
    #
    # @note This method modifies the global YARD registry.
    #
    # @param gem_yardoc_path [String] the path to the yardoc cache of a particular gem
    # @return [Array<YARD::CodeObjects::Base>]
    def load! gem_yardoc_path
      YARD::Registry.load! gem_yardoc_path
      YARD::Registry.all
    end

    # If the BUNDLE_GEMFILE environment variable is set, we need to
    # make sure it's an absolute path, as we'll be changing
    # directories.
    #
    # 'bundle exec' sets an absolute path here, but at least the
    # overcommit gem does not, breaking on-the-fly documention with a
    # spawned yardoc command from our current bundle
    #
    # @return [Hash{String => String}] a hash of environment variables to override
    def current_bundle_env_tweaks
      tweaks = {}
      # @sg-ignore Translate to something flow sensitive typing understands
      if ENV['BUNDLE_GEMFILE'] && !ENV['BUNDLE_GEMFILE'].empty?
        tweaks['BUNDLE_GEMFILE'] = File.expand_path(ENV['BUNDLE_GEMFILE'])
      end
      tweaks
    end
  end
end
