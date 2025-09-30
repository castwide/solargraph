# frozen_string_literal: true

require 'open3'

module Solargraph
  # Methods for caching and loading YARD documentation for gems.
  #
  module Yardoc
    module_function

    # Build and cache a gem's yardoc and return the path. If the cache already
    # exists, do nothing and return the path.
    #
    # @param yard_plugins [Array<String>] The names of YARD plugins to use.
    # @param gemspec [Gem::Specification]
    # @return [String] The path to the cached yardoc.
    def cache(yard_plugins, gemspec)
      path = PinCache.yardoc_path gemspec
      return path if cached?(gemspec)

      unless Dir.exist? gemspec.gem_dir
        # Can happen in at least some (old?) RubyGems versions when we
        # have a gemspec describing a standard library like bundler.
        #
        # https://github.com/apiology/solargraph/actions/runs/17650140201/job/50158676842?pr=10
        Solargraph.logger.info { "Bad info from gemspec - #{gemspec.gem_dir} does not exist" }
        return path
      end

      Solargraph.logger.info "Caching yardoc for #{gemspec.name} #{gemspec.version}"
      cmd = "yardoc --db #{path} --no-output --plugin solargraph"
      yard_plugins.each { |plugin| cmd << " --plugin #{plugin}" }
      Solargraph.logger.debug { "Running: #{cmd}" }
      # @todo set these up to run in parallel
      stdout_and_stderr_str, status = Open3.capture2e(cmd, chdir: gemspec.gem_dir)
      unless status.success?
        Solargraph.logger.warn { "YARD failed running #{cmd.inspect} in #{gemspec.gem_dir}" }
        Solargraph.logger.info stdout_and_stderr_str
      end
      path
    end

    # True if the gem yardoc is cached.
    #
    # @param gemspec [Gem::Specification]
    def cached?(gemspec)
      yardoc = File.join(PinCache.yardoc_path(gemspec), 'complete')
      File.exist?(yardoc)
    end

    # True if another process is currently building the yardoc cache.
    #
    # @param gemspec [Gem::Specification]
    def processing?(gemspec)
      yardoc = File.join(PinCache.yardoc_path(gemspec), 'processing')
      File.exist?(yardoc)
    end

    # Load a gem's yardoc and return its code objects.
    #
    # @note This method modifies the global YARD registry.
    #
    # @param gemspec [Gem::Specification]
    # @return [Array<YARD::CodeObjects::Base>]
    def load!(gemspec)
      YARD::Registry.load! PinCache.yardoc_path gemspec
      YARD::Registry.all
    end
  end
end
