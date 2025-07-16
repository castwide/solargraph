# frozen_string_literal: true

require 'pathname'
require 'benchmark'

module Solargraph
  # A collection of pins generated from required gems.  Multiple can
  # be created per workspace, to represent the pins available in
  # different files based on their 'require' lines.
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
    def initialize(requires, workspace)
      @requires = requires.compact
      @workspace = workspace
      @global_environ = Convention.for_global(self)
      load_serialized_gem_pins
      pins.concat global_environ.pins
    end

    # @return [Solargraph::PinCache]
    def pin_cache
      @pin_cache ||= workspace.fresh_pincache
    end

    # @return [Array<String>]
    def yard_plugins
      global_environ.yard_plugins
    end

    def any_uncached?
      uncached_gemspecs.any?
    end

    # Cache all pins needed for the sources in this doc_map
    # @param out [IO, nil] output stream for logging
    # @return [void]
    def cache_doc_map_gems!(out)
      # if we log at debug level:
      if logger.info?
        gem_desc = uncached_gemspecs.map { |gemspec| "#{gemspec.name}:#{gemspec.version}" }.join(', ')
        logger.info "Caching pins for gems: #{gem_desc}" unless uncached_gemspecs.empty?
      end
      logger.debug { "Caching: #{uncached_gemspecs.map(&:name)}" }
      PinCache.cache_core unless PinCache.has_core?
      load_serialized_gem_pins
      existing_pin_count = pins.length
      time = Benchmark.measure do
        uncached_gemspecs.each do |gemspec|
          cache(gemspec, out: out)
        end
      end
      pins_processed = pins.length - existing_pin_count
      milliseconds = (time.real * 1000).round
      if (milliseconds > 500) && uncached_gemspecs.any? && out && uncached_gemspecs.any?
        out.puts "Built #{pins_processed} gem pins in #{milliseconds} ms"
      end
      load_serialized_gem_pins
    end

    # @return [Array<String>]
    def unresolved_requires
      @unresolved_requires ||= required_gems_map.select { |_, gemspecs| gemspecs.nil? }.keys
    end

    # @return [Array<Gem::Specification>]
    def gemspecs
      @gemspecs ||= required_gems_map.values.compact.flatten
    end

    # @return [Set<Gem::Specification>]
    def dependencies
      @dependencies ||= (gemspecs.flat_map { |spec| workspace.fetch_dependencies(spec) } - gemspecs).to_set
    end

    private

    # Cache gem documentation if needed for this doc_map
    #
    # @param gemspec [Gem::Specification]
    # @param rebuild [Boolean] whether to rebuild the pins even if they are cached
    # @param only_if_used [Boolean]
    # @param out [IO, nil] output stream for logging
    #
    # @return [void]
    def cache(gemspec, rebuild: false, only_if_used: false, out: nil)
      return if only_if_used && !uncached_gemspecs.include?(gemspec)

      pin_cache.cache_gem(gemspec: gemspec,
                          rebuild: rebuild,
                          out: out)
    end

    # @param out [IO, nil]
    # @return [void]
    def load_serialized_gem_pins(out: $stderr)
      @pins = []
      with_gemspecs, without_gemspecs = required_gems_map.partition { |_, v| v }
      # @sg-ignore Need support for RBS duck interfaces like _ToHash
      # @type [Array<String>]
      missing_paths = Hash[without_gemspecs].keys
      # @sg-ignore Need support for RBS duck interfaces like _ToHash
      # @type [Array<Gem::Specification>]
      gemspecs = Hash[with_gemspecs].values.flatten.compact + dependencies.to_a

      missing_paths.each do |path|
        # this will load from disk if needed; no need to manage
        # uncached_gemspecs to trigger that later
        stdlib_name_guess = path.split('/').first
        rbs_pins = pin_cache.cache_stdlib_rbs_map stdlib_name_guess if stdlib_name_guess
        @pins.concat rbs_pins if rbs_pins
      end

      logger.debug { "DocMap#load_serialized_gem_pins: Combining pins..." }
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
      @required_gems_map ||= requires.to_h { |path| [path, workspace.resolve_path_to_gemspecs(path)] }
    end

    def inspect
      self.class.inspect
    end
  end
end
