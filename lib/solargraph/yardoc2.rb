# frozen_string_literal: true

require 'open3'

module Solargraph
  # Methods for caching and loading YARD documentation for gems.
  #
  module Yardoc2
    module_function

    def cache yard_plugins, metagem
      path = PinCache2.yardoc_path(metagem)
      return path if cached?(metagem)

      unless Dir.exist? metagem.full_path
        # Can happen in at least some (old?) RubyGems versions when we
        # have a gemspec describing a standard library like bundler.
        #
        # https://github.com/apiology/solargraph/actions/runs/17650140201/job/50158676842?pr=10
        Solargraph.logger.info { "Bad info from gemspec - #{metagem.full_path} does not exist" }
        return path
      end

      Solargraph.logger.info "Caching yardoc for #{metagem.cache_name}"
      cmd = "yardoc --db #{path} --no-output --plugin solargraph"
      yard_plugins.each { |plugin| cmd << " --plugin #{plugin}" }
      Solargraph.logger.debug { "Running: #{cmd}" }
      # @todo set these up to run in parallel
      # @todo Is the chdir argument being used here?
      # @sg-ignore Unrecognized keyword argument chdir to Open3.capture2e
      stdout_and_stderr_str, status = Open3.capture2e(current_bundle_env_tweaks, cmd, chdir: metagem.full_path)
      unless status.success?
        Solargraph.logger.warn { "YARD failed running #{cmd.inspect} in #{gemspec.gem_dir}" }
        Solargraph.logger.info stdout_and_stderr_str
      end
      path
    end

    def cached? metagem
      # yardoc = File.join(PinCache.yardoc_path(metagem), 'complete')
      yardoc = File.join(PinCache2.yardoc_path(metagem), 'complete')
      File.exist?(yardoc)
    end

    # Load a gem's yardoc and return its code objects.
    #
    # @note This method modifies the global YARD registry.
    #
    # @param metagem [Metagem]
    # @return [Array<YARD::CodeObjects::Base>]
    def load! metagem
      YARD::Registry.load! PinCache2.yardoc_path(metagem)
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
      # @sg-ignore Unresolved call to empty? on String, nil
      if ENV['BUNDLE_GEMFILE'] && !ENV['BUNDLE_GEMFILE'].empty?
        tweaks['BUNDLE_GEMFILE'] = File.expand_path(ENV['BUNDLE_GEMFILE'])
      end
      tweaks
    end
  end
end
