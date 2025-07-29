# frozen_string_literal: true

require 'pathname'
require 'benchmark'

module Solargraph
  # A collection of pins generated from specific 'require' statements
  # in code.  Multiple can be created per workspace, to represent the
  # pins available in different files based on their particular
  # 'require' lines.
  #
  class DocMap
    include Logging

    # @return [Array<String>]
    attr_reader :requires
    alias required requires

    # @return [Array<Pin::Base>]
    attr_reader :pins

    attr_reader :global_environ

    # @return [Array<Gem::Specification>]
    def uncached_gemspecs
      @uncached_gemspecs ||= []
    end

    # @return [Workspace]
    attr_reader :workspace

    # @param requires [Array<String>]
    # @param workspace [Workspace]
    # @param out [IO, nil] output stream for logging
    def initialize requires, workspace, out: $stderr
      @requires = requires.compact
      @workspace = workspace
      @global_environ = Convention.for_global(self)
      load_serialized_gem_pins(out: out)
      pins.concat global_environ.pins
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
      load_serialized_gem_pins(out: out)
      time = Benchmark.measure do
        uncached_gemspecs.each do |gemspec|
          cache(gemspec, out: out)
        end
      end
      milliseconds = (time.real * 1000).round
      if (milliseconds > 500) && uncached_gemspecs.any? && out && uncached_gemspecs.any?
        out.puts "Built #{uncached_gemspecs.length} gems in #{milliseconds} ms"
      end
      load_serialized_gem_pins(out: out)
    end

    # @return [Array<String>]
    def unresolved_requires
      @unresolved_requires ||= required_gems_map.select { |_, gemspecs| gemspecs.nil? }.keys
    end

    # @param out [IO, nil] output stream for logging
    # @return [Set<Gem::Specification>]
    def dependencies out: $stderr
      @dependencies ||= (gemspecs.flat_map { |spec| workspace.fetch_dependencies(spec, out: out) } - gemspecs).to_set
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
    # @return [void]
    def load_serialized_gem_pins out: $stderr
      @pins = []
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
          @pins.concat rbs_pins if rbs_pins
        end
      end

      existing_pin_count = pins.length
      time = Benchmark.measure do
        gemspecs.each do |gemspec|
          # only deserializes already-cached gems
          pins = pin_cache.deserialize_combined_pin_cache gemspec
          if pins
            @pins.concat pins
          else
            uncached_gemspecs << gemspec
          end
        end
      end
      pins_processed = pins.length - existing_pin_count
      milliseconds = (time.real * 1000).round
      if (milliseconds > 500) && out && gemspecs.any?
        out.puts "Deserialized #{pins.length} gem pins from #{PinCache.base_dir} in #{milliseconds} ms"
      end
      uncached_gemspecs.uniq! { |gemspec| "#{gemspec.name}:#{gemspec.version}" }
      nil
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
