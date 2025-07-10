# frozen_string_literal: true

module Solargraph
  # Methods for caching and loading YARD documentation for gems.
  #
  module Yardoc
    module_function

    # Build and cache a gem's yardoc and return the path. If the cache already
    # exists, do nothing and return the path.
    #
    # @param gemspec [Gem::Specification]
    # @return [String] The path to the cached yardoc.
    def cache(gemspec)
      path = PinCache.yardoc_path gemspec
      return path if cached?(gemspec)

      Solargraph.logger.info "Caching yardoc for #{gemspec.name} #{gemspec.version}"
      Dir.chdir gemspec.gem_dir do
        `yardoc --db #{path} --no-output --plugin solargraph`
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
