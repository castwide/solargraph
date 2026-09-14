# frozen_string_literal: true

module Solargraph
  class External
    # autoload :Metagem,   'solargraph/external/metagem'
    autoload :Repo, 'solargraph/external/repo'
    # autoload :Require,   'solargraph/external/require'

    attr_reader :requires

    attr_reader :unresolved_requires

    attr_reader :loaded_gems

    attr_reader :unloaded_gems

    attr_reader :pins

    # @param bench [Bench]
    def initialize bench, cached: true
      @requires = select_external_requires(bench)
      @cached = cached
      @repo = Repo.new(bench.workspace.directory)
      @pins = []
      @unresolved_requires = []
      @loaded_gems = []
      @unloaded_gems = []
      bundler_require = false
      @requires.each do |path|
        if path == 'bundler/require'
          bundler_require = true
        end
        metagem = @repo.find_by_path(path)
        next @unresolved_requires.push(path) unless metagem
        if metagem.cacheable? && cached?
          process_cached_gem(metagem)
        else
          process_uncached_gem(metagem)
        end
      end
    end

    def cached?
      @cached
    end

    def update bench
      new_requires = select_external_requires(bench)
      if requires == new_requires
        return if uncached_gems.empty?
        # @todo try to cache gems
      else
        @requires = new_requires
        # @todo rest of update
      end
    end

    private

    def select_external_requires bench
      bench.source_maps
           .flat_map(&:requires)
           .map(&:name)
           .reject { |path| bench.workspace.would_require?(path) }
    end

    # @param metagem [Metagem]
    def process_cached_gem(metagem)
      if GemCache.exist?(metagem)
        @pins.concat GemCache.load(metagem)
        @loaded_gems.push metagem
      else
        @unloaded_gems.push metagem
      end
    end

    # @param metagem [Metagem]
    def process_uncached_gem(metagem)
      # @todo Consider leveraging require_paths to load source maps
      workspace = Workspace.new(metagem.full_path)
      source_maps = workspace.sources.map { |source| Solargraph::SourceMap.new(source) }
      source_pins = source_maps.flat_map(&:pins)
      rbs_pins = RbsMap2.new(metagem).pins
      combined = GemPins.combine(source_pins, rbs_pins)
      @pins.concat combined
      @loaded_gems.push(metagem)
    end
  end
end
