# frozen_string_literal: true

module Solargraph
  class External
    # autoload :Metagem,   'solargraph/external/metagem'
    autoload :Repo, 'solargraph/external/repo'
    # autoload :Require,   'solargraph/external/require'

    attr_reader :requires

    # @param bench [Bench]
    def initialize bench, cached: true
      @requires = select_external_requires(bench)
      @cached = cached
      @repo = Repo.new(bench.workspace.directory)
      @pins = []
      bundler_require = false
      @requires.each do |path|
        if path == 'bundler/require'
          bundler_require = true
        end
        metagem = @repo.find_by_path(path)
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

    def process_cached_gem(metagem)
      if Yardoc2.cached?(metagem)
        Yardoc2.load!(metagem)
      else
        puts "#{metagem.cache_name} is NOT cached."
      end
    end

    def process_uncached_gem(metagem)
      puts "And dis is where I just load it in place!!1!"
    end
  end
end
