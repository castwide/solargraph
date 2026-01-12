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

    # @return [Array<String>]
    attr_reader :requires
    alias required requires

    # @return [Array<Pin::Base>]
    attr_reader :pins

    # @return [Array<Gem::Specification>]
    def uncached_gemspecs
      uncached_yard_gemspecs.concat(uncached_rbs_collection_gemspecs)
                            .sort_by { |gemspec| "#{gemspec.name}:#{gemspec.version}" }
                            .uniq { |gemspec| "#{gemspec.name}:#{gemspec.version}" }
    end

    # @return [Array<Gem::Specification>]
    attr_reader :uncached_yard_gemspecs

    # @return [Array<Gem::Specification>]
    attr_reader :uncached_rbs_collection_gemspecs

    # @return [String, nil]
    attr_reader :rbs_collection_path

    # @return [String, nil]
    attr_reader :rbs_collection_config_path

    # @return [Workspace, nil]
    attr_reader :workspace

    # @return [Environ]
    attr_reader :environ

    # @param requires [Array<String>]
    # @param workspace [Workspace, nil]
    # @param out [IO, nil] output stream for logging
    def initialize requires, workspace, out: $stderr
      @requires = requires.compact
      @workspace = workspace
      @rbs_collection_path = workspace&.rbs_collection_path
      @rbs_collection_config_path = workspace&.rbs_collection_config_path
      @environ = Convention.for_global(self)
      @requires.concat @environ.requires if @environ
      load_serialized_gem_pins
      pins.concat @environ.pins
    end

    # @param out [IO]
    # @return [void]
    def cache_all!(out)
      # if we log at debug level:
      if logger.info?
        gem_desc = uncached_gemspecs.map { |gemspec| "#{gemspec.name}:#{gemspec.version}" }.join(', ')
        logger.info "Caching pins for gems: #{gem_desc}" unless uncached_gemspecs.empty?
      end
      logger.debug { "Caching for YARD: #{uncached_yard_gemspecs.map(&:name)}" }
      logger.debug { "Caching for RBS collection: #{uncached_rbs_collection_gemspecs.map(&:name)}" }
      load_serialized_gem_pins
      uncached_gemspecs.each do |gemspec|
        cache(gemspec, out: out)
      end
      load_serialized_gem_pins
      @uncached_rbs_collection_gemspecs = []
      @uncached_yard_gemspecs = []
    end

    # @param gemspec [Gem::Specification]
    # @param out [IO]
    # @return [void]
    def cache_yard_pins(gemspec, out)
      pins = GemPins.build_yard_pins(yard_plugins, gemspec)
      PinCache.serialize_yard_gem(gemspec, pins)
      logger.info { "Cached #{pins.length} YARD pins for gem #{gemspec.name}:#{gemspec.version}" } unless pins.empty?
    end

    # @param gemspec [Gem::Specification]
    # @param out [IO]
    # @return [void]
    def cache_rbs_collection_pins(gemspec, out)
      rbs_map = RbsMap.from_gemspec(gemspec, rbs_collection_path, rbs_collection_config_path)
      pins = rbs_map.pins
      rbs_version_cache_key = rbs_map.cache_key
      # cache pins even if result is zero, so we don't retry building pins
      pins ||= []
      PinCache.serialize_rbs_collection_gem(gemspec, rbs_version_cache_key, pins)
      logger.info { "Cached #{pins.length} RBS collection pins for gem #{gemspec.name} #{gemspec.version} with cache_key #{rbs_version_cache_key.inspect}" unless pins.empty? }
    end

    # @param gemspec [Gem::Specification]
    # @param rebuild [Boolean] whether to rebuild the pins even if they are cached
    # @param out [IO, nil] output stream for logging
    # @return [void]
    def cache(gemspec, rebuild: false, out: nil)
      build_yard = uncached_yard_gemspecs.map { |gs| "#{gs.name}:#{gs.version}" }.include?("#{gemspec.name}:#{gemspec.version}") || rebuild
      build_rbs_collection = uncached_rbs_collection_gemspecs.map { |gs| "#{gs.name}:#{gs.version}" }.include?("#{gemspec.name}:#{gemspec.version}") || rebuild
      if build_yard || build_rbs_collection
        type = []
        type << 'YARD' if build_yard
        type << 'RBS collection' if build_rbs_collection
        out.puts("Caching #{type.join(' and ')} pins for gem #{gemspec.name}:#{gemspec.version}") if out
      end
      cache_yard_pins(gemspec, out) if build_yard
      cache_rbs_collection_pins(gemspec, out) if build_rbs_collection
    end

    # @return [Array<Gem::Specification>]
    def gemspecs
      @gemspecs ||= required_gems_map.values.compact.flatten
    end

    # @return [Array<String>]
    def unresolved_requires
      @unresolved_requires ||= required_gems_map.select { |_, gemspecs| gemspecs.nil? }.keys
    end

    # @return [Hash{Array(String, String) => Array<Pin::Base>}] Indexed by gemspec name and version
    def self.all_yard_gems_in_memory
      @yard_gems_in_memory ||= {}
    end

    # @return [Hash{String => Hash{Array(String, String) => Array<Pin::Base>}}] stored by RBS collection path
    def self.all_rbs_collection_gems_in_memory
      @rbs_collection_gems_in_memory ||= {}
    end

    # @return [Hash{Array(String, String) => Array<Pin::Base>}] Indexed by gemspec name and version
    def yard_pins_in_memory
      self.class.all_yard_gems_in_memory
    end

    # @return [Hash{Array(String, String) => Array<Pin::Base>}] Indexed by gemspec name and version
    def rbs_collection_pins_in_memory
      self.class.all_rbs_collection_gems_in_memory[rbs_collection_path] ||= {}
    end

    # @return [Hash{Array(String, String) => Array<Pin::Base>}] Indexed by gemspec name and version
    def self.all_combined_pins_in_memory
      @combined_pins_in_memory ||= {}
    end

    # @todo this should also include an index by the hash of the RBS collection
    # @return [Hash{Array(String, String) => Array<Pin::Base>}] Indexed by gemspec name and version
    def combined_pins_in_memory
      self.class.all_combined_pins_in_memory
    end

    # @return [Array<String>]
    def yard_plugins
      @environ.yard_plugins
    end

    # @return [Set<Gem::Specification>]
    def dependencies
      @dependencies ||= (gemspecs.flat_map { |spec| workspace.fetch_dependencies(spec) } - gemspecs).to_set
    end

    private

    # @return [void]
    def load_serialized_gem_pins
      @pins = []
      @uncached_yard_gemspecs = []
      @uncached_rbs_collection_gemspecs = []
      with_gemspecs, without_gemspecs = required_gems_map.partition { |_, v| v }
      # @sg-ignore Need support for RBS duck interfaces like _ToHash
      # @type [Array<String>]
      paths = Hash[without_gemspecs].keys
      # @sg-ignore Need support for RBS duck interfaces like _ToHash
      # @type [Array<Gem::Specification>]
      gemspecs = Hash[with_gemspecs].values.flatten.compact + dependencies.to_a

      paths.each do |path|
        rbs_pins = deserialize_stdlib_rbs_map path
      end

      logger.debug { "DocMap#load_serialized_gem_pins: Combining pins..." }
      time = Benchmark.measure do
        gemspecs.each do |gemspec|
          pins = deserialize_combined_pin_cache gemspec
          @pins.concat pins if pins
        end
      end
      logger.info { "DocMap#load_serialized_gem_pins: Loaded and processed serialized pins together in #{time.real} seconds" }
      @uncached_yard_gemspecs.uniq!
      @uncached_rbs_collection_gemspecs.uniq!
      nil
    end

    # @return [Hash{String => Array<Gem::Specification>}]
    def required_gems_map
      @required_gems_map ||= requires.to_h { |path| [path, workspace.resolve_require(path)] }
    end

    # @param gemspec [Gem::Specification]
    # @return [Array<Pin::Base>, nil]
    def deserialize_yard_pin_cache gemspec
      if yard_pins_in_memory.key?([gemspec.name, gemspec.version])
        return yard_pins_in_memory[[gemspec.name, gemspec.version]]
      end

      cached = PinCache.deserialize_yard_gem(gemspec)
      if cached
        logger.info { "Loaded #{cached.length} cached YARD pins from #{gemspec.name}:#{gemspec.version}" }
        yard_pins_in_memory[[gemspec.name, gemspec.version]] = cached
        cached
      else
        logger.debug "No YARD pin cache for #{gemspec.name}:#{gemspec.version}"
        @uncached_yard_gemspecs.push gemspec
        nil
      end
    end

    # @param gemspec [Gem::Specification]
    # @return [void]
    def deserialize_combined_pin_cache(gemspec)
      unless combined_pins_in_memory[[gemspec.name, gemspec.version]].nil?
        return combined_pins_in_memory[[gemspec.name, gemspec.version]]
      end

      rbs_map = RbsMap.from_gemspec(gemspec, rbs_collection_path, rbs_collection_config_path)
      rbs_version_cache_key = rbs_map.cache_key

      cached = PinCache.deserialize_combined_gem(gemspec, rbs_version_cache_key)
      if cached
        logger.info { "Loaded #{cached.length} cached YARD pins from #{gemspec.name}:#{gemspec.version}" }
        combined_pins_in_memory[[gemspec.name, gemspec.version]] = cached
        return combined_pins_in_memory[[gemspec.name, gemspec.version]]
      end

      rbs_collection_pins = deserialize_rbs_collection_cache gemspec, rbs_version_cache_key

      yard_pins = deserialize_yard_pin_cache gemspec

      if !rbs_collection_pins.nil? && !yard_pins.nil?
        logger.debug { "Combining pins for #{gemspec.name}:#{gemspec.version}" }
        combined_pins = GemPins.combine(yard_pins, rbs_collection_pins)
        PinCache.serialize_combined_gem(gemspec, rbs_version_cache_key, combined_pins)
        combined_pins_in_memory[[gemspec.name, gemspec.version]] = combined_pins
        logger.info { "Generated #{combined_pins_in_memory[[gemspec.name, gemspec.version]].length} combined pins for #{gemspec.name} #{gemspec.version}" }
        return combined_pins
      end

      if !yard_pins.nil?
        logger.debug { "Using only YARD pins for #{gemspec.name}:#{gemspec.version}" }
        combined_pins_in_memory[[gemspec.name, gemspec.version]] = yard_pins
        return combined_pins_in_memory[[gemspec.name, gemspec.version]]
      elsif !rbs_collection_pins.nil?
        logger.debug { "Using only RBS collection pins for #{gemspec.name}:#{gemspec.version}" }
        combined_pins_in_memory[[gemspec.name, gemspec.version]] = rbs_collection_pins
        return combined_pins_in_memory[[gemspec.name, gemspec.version]]
      else
        logger.debug { "Pins not yet cached for #{gemspec.name}:#{gemspec.version}" }
        return nil
      end
    end

    # @param path [String] require path that might be in the RBS stdlib collection
    # @return [void]
    def deserialize_stdlib_rbs_map path
      map = RbsMap::StdlibMap.load(path)
      if map.resolved?
        logger.debug { "Loading stdlib pins for #{path}" }
        @pins.concat map.pins
        logger.debug { "Loaded #{map.pins.length} stdlib pins for #{path}" }
        map.pins
      else
        # @todo Temporarily ignoring unresolved `require 'set'`
        logger.debug { "Require path #{path} could not be resolved in RBS" } unless path == 'set'
        nil
      end
    end

    # @param gemspec [Gem::Specification]
    # @param rbs_version_cache_key [String]
    # @return [Array<Pin::Base>, nil]
    def deserialize_rbs_collection_cache gemspec, rbs_version_cache_key
      key = "#{gemspec.name}:#{gemspec.version}"
      return if rbs_collection_pins_in_memory.key?([key, rbs_version_cache_key])
      cached = PinCache.deserialize_rbs_collection_gem(gemspec, rbs_version_cache_key)
      if cached
        logger.info { "Loaded #{cached.length} pins from RBS collection cache for #{gemspec.name}:#{gemspec.version}" } unless cached.empty?
        rbs_collection_pins_in_memory[[key, rbs_version_cache_key]] = cached
        cached
      else
        logger.debug "No RBS collection pin cache for #{gemspec.name} #{gemspec.version}"
        @uncached_rbs_collection_gemspecs.push gemspec
        nil
      end
    end

    def inspect
      self.class.inspect
    end
  end
end
