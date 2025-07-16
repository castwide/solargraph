# frozen_string_literal: true

module Solargraph
  # Methods for caching and loading YARD documentation for gems.
  #
  module Yardoc
    module_function

    # Build and save a gem's yardoc into a given path.
    #
    # @param yardoc_path [String]
    # @param yard_plugins [Array<String>]
    # @param gemspec [Gem::Specification]
    #
    # @return [void]
    def build_docs(yardoc_path, yard_plugins, gemspec)
      return if docs_built?(yardoc_path, gemspec)

      Solargraph.logger.info "Saving yardoc for #{gemspec.name} #{gemspec.version} into #{yardoc_path}"
      cmd = "yardoc --db #{yardoc_path} --no-output --plugin solargraph"
      yard_plugins.each { |plugin| cmd << " --plugin #{plugin}" }
      Solargraph.logger.debug { "Running: #{cmd}" }
      # @todo set these up to run in parallel
      #
      # @sg-ignore RBS gem doesn't reflect that Open3.* also include
      #   kwopts from Process.spawn()
      stdout_and_stderr_str, status = Open3.capture2e(cmd, chdir: gemspec.gem_dir)
      return if status.success?
      Solargraph.logger.warn { "YARD failed running #{cmd.inspect} in #{gemspec.gem_dir}" }
      Solargraph.logger.info stdout_and_stderr_str
    end

    # @param yardoc_path [String] the path to the yardoc cache
    # @param gemspec [Gem::Specification]
    # @param out [IO, nil] where to log messages
    # @return [Array<Pin::Base>]
    def build_pins(yardoc_path, gemspec, out: $stderr)
      yardoc = load!(yardoc_path, gemspec)
      YardMap::Mapper.new(yardoc, gemspec).map
    end

    # True if the gem yardoc is cached.
    #
    # @param yardoc_path [String]
    # @param gemspec [Gem::Specification]
    def docs_built?(yardoc_path, gemspec)
      yardoc = File.join(yardoc_path, 'complete')
      File.exist?(yardoc)
    end

    # True if another process is currently building the yardoc cache.
    #
    # @param yardoc_path [String]
    def processing?(yardoc_path)
      yardoc = File.join(yardoc_path, 'processing')
      File.exist?(yardoc)
    end

    # Load a gem's yardoc and return its code objects.
    #
    # @note This method modifies the global YARD registry.
    #
    # @param yardoc_path [String]
    # @param gemspec [Gem::Specification]
    # @return [Array<YARD::CodeObjects::Base>]
    def load!(yardoc_path, gemspec)
      YARD::Registry.load! yardoc_path
      YARD::Registry.all
    end
  end
end
