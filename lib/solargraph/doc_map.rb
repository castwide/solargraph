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

    # @param requires [Array<String>]
    # @param workspace [Workspace]
    # @param out [IO, nil] output stream for logging
    def initialize requires, workspace, out: $stderr
      @provided_requires = requires.compact
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
    # @param out [IO, nil] output stream for logging
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

    # @return [Set<Gem::Specification>]
    # @param out [IO]
    def dependencies out: $stderr
      @dependencies ||=
        begin
          all_deps = gemspecs.flat_map { |spec| workspace.fetch_dependencies(spec, out: out) }
          existing_gems = gemspecs.map(&:name)
          all_deps.reject { |gemspec| existing_gems.include? gemspec.name }.to_set
        end
    end

    # Cache gem documentation if needed for this doc_map
    #
    # @param gemspec [Gem::Specification]
    # @param rebuild [Boolean] whether to rebuild the pins even if they are cached
    # @param out [IO, nil] output stream for logging
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
      # @sg-ignore Wrong argument type for Hash.[]: arg_0 expected _ToHash<Array(String, Array<Gem::Specification>), undefined>, received Array<Array(String, Array<Gem::Specification>)>
      # @type [Array<String>]
      missing_paths = Hash[without_gemspecs].keys
      # @sg-ignore Wrong argument type for Hash.[]: arg_0 expected _ToHash<Array(String, Array<Gem::Specification>), undefined>, received Array<Array(String, Array<Gem::Specification>)>
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
      @required_gems_map ||= requires.to_h { |require| [require, workspace.resolve_require(require)] }
    end

    def inspect
      self.class.inspect
    end
  end
end
