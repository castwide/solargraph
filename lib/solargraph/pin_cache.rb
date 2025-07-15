require 'fileutils'
require 'rbs'
require 'rubygems'

module Solargraph
  class PinCache
    include Logging

    attr_reader :directory, :rbs_collection_path, :rbs_collection_config_path, :yard_plugins

    # @param rbs_collection_path [String, nil]
    # @param rbs_collection_config_path [String, nil]
    # @param directory [String, nil]
    # @param yard_plugins [Array<String>]
    def initialize(rbs_collection_path:, rbs_collection_config_path:,
                   directory:,
                   yard_plugins:)
      @rbs_collection_path = rbs_collection_path
      @rbs_collection_config_path = rbs_collection_config_path
      @directory = directory
      @yard_plugins = yard_plugins
    end

    # @sg-ignore
    # @param gemspec [Gem::Specification, Bundler::LazySpecification]
    def cached?(gemspec)
      rbs_version_cache_key = lookup_rbs_version_cache_key(gemspec)
      has_combined_gem?(gemspec, rbs_version_cache_key)
    end

    # @param gemspec [Gem::Specification, Bundler::LazySpecification]
    # @param rebuild [Boolean] whether to rebuild the cache regardless of whether it already exists
    # @param out [IO, nil] output stream for logging
    # @return [void]
    def cache_gem(gemspec:, rebuild: false, out: nil)
      rbs_version_cache_key = lookup_rbs_version_cache_key(gemspec)
      if rebuild
        build_yard = true
        build_rbs_collection = true
        build_combined = true
      else
        build_yard = !has_yard_gem?(gemspec)
        build_rbs_collection = !has_rbs_collection_pins?(gemspec, rbs_version_cache_key)
        build_combined = !has_combined_gem?(gemspec, rbs_version_cache_key) || build_yard || build_rbs_collection
      end

      build_yard = false if suppress_yard_cache?(gemspec, rbs_version_cache_key)

      return unless build_yard || build_rbs_collection || build_combined

      type = []
      type << 'YARD' if build_yard
      rbs_source_desc = RbsMap.rbs_source_desc(rbs_version_cache_key)
      type << rbs_source_desc if build_rbs_collection && !rbs_source_desc.nil?
      # we'll build it anyway, but it won't take long to build with
      # only a single source
      type << 'combined' if build_combined && !rbs_source_desc.nil?
      out.puts("Caching #{type.join(' and ')} pins for gem #{gemspec.name}:#{gemspec.version}") if out

      cache_yard_pins(gemspec, out) if build_yard
      yard_pins = deserialize_yard_pin_cache(gemspec)

      cache_rbs_collection_pins(gemspec, out) if build_rbs_collection
      rbs_collection_pins = deserialize_rbs_collection_cache(gemspec, rbs_version_cache_key)

      cache_combined_pins(gemspec, rbs_version_cache_key, yard_pins, rbs_collection_pins) if build_combined
    end

    def suppress_yard_cache?(gemspec, rbs_version_cache_key)
      # TODO test this - saw: Caching YARD and RBS collection and combined pins for gem parser:3.3.8.0
      if gemspec == 'parser' && rbs_version_cache_key != CACHE_KEY_UNRESOLVED
        # parser takes forever to build YARD pins, but has excellent RBS collection pins
        return true
      end
      false
    end

    # @param path [String] require path that might be in the RBS stdlib collection
    # @return [void]
    def cache_stdlib_rbs_map path
      # these are held in memory in RbsMap::StdlibMap
      map = RbsMap::StdlibMap.load(path)
      if map.resolved?
        logger.debug { "Loading stdlib pins for #{path}" }
        pins = map.pins
        logger.debug { "Loaded #{pins.length} stdlib pins for #{path}" }
        pins
      else
        # @todo Temporarily ignoring unresolved `require 'set'`
        logger.debug { "Require path #{path} could not be resolved in RBS" } unless path == 'set'
        nil
      end
    end

    # @param gemspec [Gem::Specification, Bundler::LazySpecification]
    # @return [String]
    def lookup_rbs_version_cache_key(gemspec)
      rbs_map = RbsMap.from_gemspec(gemspec, rbs_collection_path, rbs_collection_config_path)
      rbs_map.cache_key
    end

    # @param gemspec [Gem::Specification]
    # @param rbs_version_cache_key [String]
    # @param yard_pins [Array<Pin::Base>]
    # @param rbs_collection_pins [Array<Pin::Base>]
    # @return [void]
    def cache_combined_pins(gemspec, rbs_version_cache_key, yard_pins, rbs_collection_pins)
      combined_pins = GemPins.combine(yard_pins, rbs_collection_pins)
      serialize_combined_gem(gemspec, rbs_version_cache_key, combined_pins)
    end

    # @param gemspec [Gem::Specification]
    # @return [void]
    def deserialize_combined_pin_cache(gemspec)
      unless combined_pins_in_memory[[gemspec.name, gemspec.version]].nil?
        return combined_pins_in_memory[[gemspec.name, gemspec.version]]
      end

      rbs_version_cache_key = lookup_rbs_version_cache_key(gemspec)

      cached = load_combined_gem(gemspec, rbs_version_cache_key)
      if cached
        logger.info { "Loaded #{cached.length} cached YARD pins from #{gemspec.name}:#{gemspec.version}" }
        combined_pins_in_memory[[gemspec.name, gemspec.version]] = cached
        return combined_pins_in_memory[[gemspec.name, gemspec.version]]
      end
    end

    # @param gemspec [Gem::Specification]
    # @param out [IO, nil]
    # @return [void]
    def uncache_gem(gemspec, out: nil)
      PinCache.uncache(yardoc_path(gemspec), out: out)
      uncache_by_prefix(rbs_collection_pins_path_prefix(gemspec), out: out)
      PinCache.uncache(yard_gem_path(gemspec), out: out)
      uncache_by_prefix(combined_path_prefix(gemspec), out: out)
    end

    private

    # @param gemspec [Gem::Specification, Bundler::LazySpecification]
    # @param out [IO, nil]
    # @return [Array<Pin::Base>]
    def cache_yard_pins(gemspec, out)
      yardoc_dir = yardoc_path(gemspec)
      unless Yardoc.docs_built?(yardoc_dir, gemspec)
        Yardoc.build_docs(yardoc_dir, yard_plugins, gemspec)
      end
      pins = Yardoc.build_pins(yardoc_dir, gemspec, out)
      serialize_yard_gem(gemspec, pins)
      logger.info { "Cached #{pins.length} YARD pins for gem #{gemspec.name}:#{gemspec.version}" } unless pins.empty?
      pins
    end

    # @return [Hash{Array(String, String) => Array<Pin::Base>}] gemspec name, version
    def yard_pins_in_memory
      PinCache.all_yard_pins_in_memory[yard_plugins] ||= {}
    end

    # @return [Hash{Array(String, String, String) => Array<Pin::Base>}] gemspec name, version and rbs version cache key
    def rbs_collection_pins_in_memory
      PinCache.all_rbs_collection_pins_in_memory ||= {}
    end

    # @return [Hash{Array(String, String, String) => Array<Pin::Base>}]
    def combined_pins_in_memory
      PinCache.all_combined_pins_in_memory[yard_plugins] ||= {}
    end

    # @param gemspec [Gem::Specification]
    # @param out [IO, nil]
    # @return [Array<Pin::Base>]
    def cache_rbs_collection_pins(gemspec, out)
      rbs_map = RbsMap.from_gemspec(gemspec, rbs_collection_path, rbs_collection_config_path)
      pins = rbs_map.pins
      rbs_version_cache_key = rbs_map.cache_key
      # cache pins even if result is zero, so we don't retry building pins
      pins ||= []
      serialize_rbs_collection_pins(gemspec, rbs_version_cache_key, pins)
      logger.info { "Cached #{pins.length} RBS collection pins for gem #{gemspec.name} #{gemspec.version} with cache_key #{rbs_version_cache_key.inspect}" unless pins.empty? }
      pins
    end

    # @param gemspec [Gem::Specification]
    # @return [Array<Pin::Base>]
    def deserialize_yard_pin_cache gemspec
      if yard_pins_in_memory.key?([gemspec.name, gemspec.version])
        return yard_pins_in_memory[[gemspec.name, gemspec.version]]
      end

      cached = load_yard_gem(gemspec)
      if cached
        logger.info { "Loaded #{cached.length} cached YARD pins from #{gemspec.name}:#{gemspec.version}" }
        yard_pins_in_memory[[gemspec.name, gemspec.version]] = cached
        cached
      else
        logger.debug "No YARD pin cache for #{gemspec.name}:#{gemspec.version}"
        nil
      end
    end

    # @param gemspec [Gem::Specification, Bundler::LazySpecification]
    # @param rbs_version_cache_key [String]
    # @return [Array<Pin::Base>, nil]
    def deserialize_rbs_collection_cache gemspec, rbs_version_cache_key
      return if rbs_collection_pins_in_memory.key?([gemspec.name, gemspec.version, rbs_version_cache_key])
      cached = load_rbs_collection_pins(gemspec, rbs_version_cache_key)
      if cached
        logger.info { "Loaded #{cached.length} pins from RBS collection cache for #{gemspec.name}:#{gemspec.version}" } unless cached.empty?
        rbs_collection_pins_in_memory[[gemspec.name, gemspec.version, rbs_version_cache_key]] = cached
        cached
      else
        logger.debug "No RBS collection pin cache for #{gemspec.name} #{gemspec.version}"
        nil
      end
    end

    # @return [Array<String>]
    def yard_path_components
      ["yard-#{YARD::VERSION}",
       yard_plugins.sort.uniq.join('-')]
    end

    # @param gemspec [Gem::Specification]
    # @return [String]
    def yardoc_path gemspec
      File.join(PinCache.base_dir,
                *yard_path_components,
                "#{gemspec.name}-#{gemspec.version}.yardoc")
    end

    # @param gemspec [Gem::Specification]
    # @return [String]
    def yard_gem_path gemspec
      File.join(PinCache.work_dir, *yard_path_components, "#{gemspec.name}-#{gemspec.version}.ser")
    end

    # @param gemspec [Gem::Specification]
    # @return [Array<Pin::Base>]
    def load_yard_gem(gemspec)
      PinCache.load(yard_gem_path(gemspec))
    end

    # @param gemspec [Gem::Specification]
    # @param pins [Array<Pin::Base>]
    # @return [void]
    def serialize_yard_gem(gemspec, pins)
      PinCache.save(yard_gem_path(gemspec), pins)
    end

    # @param gemspec [Gem::Specification]
    # @return [Boolean]
    def has_yard_gem?(gemspec)
      exist?(yard_gem_path(gemspec))
    end

    # @param gemspec [Gem::Specification]
    # @return [Boolean]
    def has_yardoc?(gemspec)
      exist?(yardoc_path(gemspec))
    end

    # @param gemspec [Gem::Specification]
    # @param hash [String, nil]
    # @return [String]
    def rbs_collection_pins_path(gemspec, hash)
      rbs_collection_pins_path_prefix(gemspec) + "#{gemspec.name}-#{gemspec.version}-#{hash || 0}.ser"
    end

    # @param gemspec [Gem::Specification]
    # @return [String]
    def rbs_collection_pins_path_prefix(gemspec)
      File.join(PinCache.work_dir, 'rbs', "#{gemspec.name}-#{gemspec.version}-")
    end

    # @param gemspec [Gem::Specification, Bundler::LazySpecification]
    # @param hash [String]
    #
    # @return [Array<Pin::Base>]
    def load_rbs_collection_pins(gemspec, hash)
      PinCache.load(rbs_collection_pins_path(gemspec, hash))
    end

    # @param gemspec [Gem::Specification]
    # @param hash [String, nil]
    # @param pins [Array<Pin::Base>]n
    # @return [void]
    def serialize_rbs_collection_pins(gemspec, hash, pins)
      PinCache.save(rbs_collection_pins_path(gemspec, hash), pins)
    end

    # @param gemspec [Gem::Specification]
    # @param hash [String, nil]
    # @return [String]
    def combined_path(gemspec, hash)
      File.join(combined_path_prefix(gemspec) + "-#{hash || 0}.ser")
    end

    # @param gemspec [Gem::Specification]
    # @return [String]
    def combined_path_prefix(gemspec)
      File.join(PinCache.work_dir, 'combined', yard_plugins.sort.join('-'), "#{gemspec.name}-#{gemspec.version}")
    end

    # @param gemspec [Gem::Specification]
    # @param hash [String, nil]
    # @param pins [Array<Pin::Base>]
    # @return [void]
    def serialize_combined_gem(gemspec, hash, pins)
      PinCache.save(combined_path(gemspec, hash), pins)
    end

    # @param gemspec [Gem::Specification, Bundler::LazySpecification]
    # @param hash [String]
    def has_combined_gem?(gemspec, hash)
      exist?(combined_path(gemspec, hash))
    end

    # @param gemspec [Gem::Specification]
    # @param hash [String, nil]
    # @return [Array<Pin::Base>]
    def load_combined_gem gemspec, hash
      PinCache.load(combined_path(gemspec, hash))
    end

    # @param gemspec [Gem::Specification]
    # @param hash [String]
    def has_rbs_collection_pins?(gemspec, hash)
      exist?(rbs_collection_pins_path(gemspec, hash))
    end

    include Logging

    # @param path [String]
    def exist? *path
      File.file? File.join(*path)
    end

    # @return [void]
    # @param path_segments [Array<String>]
    def uncache_by_prefix *path_segments, out: nil
      path = File.join(*path_segments)
      glob = "#{path}*"
      out.puts "Clearing pin cache in #{glob}" unless out.nil?
      Dir.glob(glob).each do |file|
        next unless File.file?(file)
        FileUtils.rm_rf file, secure: true
        out.puts "Clearing pin cache in #{file}" unless out.nil?
      end
    end

    class << self
      include Logging

      # @return [Hash{Array<String> => Hash{Array(String, String) => Array<Pin::Base>}}] yard plugins, then gemspec name and version
      def all_yard_pins_in_memory
        @all_yard_pins_in_memory ||= {}
      end

      # @return [Hash{Array(String, String, String) => Array<Pin::Base>}] gemspec name, version and rbs version cache key
      def all_rbs_collection_pins_in_memory
        @all_rbs_collection_pins_in_memory ||= {}
      end

      # @return [Hash{Array<String> => Hash{Array(String, String) => Array<Pin::Base>}}] yard plugins, then gemspec name and version
      def all_combined_pins_in_memory
        @all_combined_pins_in_memory ||= {}
      end

      # The base directory where cached YARD documentation and serialized pins are serialized
      #
      # @return [String]
      def base_dir
        # The directory is not stored in a variable so it can be overridden
        # in specs.
        ENV['SOLARGRAPH_CACHE'] ||
          (ENV['XDG_CACHE_HOME'] ? File.join(ENV['XDG_CACHE_HOME'], 'solargraph') : nil) ||
          File.join(Dir.home, '.cache', 'solargraph')
      end

      # @param path_segments [Array<String>]
      # @return [void]
      def uncache *path_segments, out: nil
        path = File.join(*path_segments)
        if File.exist?(path)
          FileUtils.rm_rf path, secure: true
          out.puts "Clearing pin cache in #{path}" unless out.nil?
        else
          out.puts "Pin cache file #{path} does not exist" unless out.nil?
        end
      end

      # @param out [IO, nil]
      # @return [void]
      def uncache_core(out: nil)
        uncache(core_path, out: out)
      end

      # @param out [IO, nil]
      # @return [void]
      def uncache_stdlib(out: nil)
        uncache(stdlib_path, out: out)
      end

      # @return [void]
      def clear
        FileUtils.rm_rf base_dir, secure: true
      end

      # The working directory for the current Ruby, RBS, and Solargraph versions.
      #
      # @return [String]
      def work_dir
        # The directory is not stored in a variable so it can be overridden
        # in specs.
        File.join(base_dir, "ruby-#{RUBY_VERSION}", "rbs-#{RBS::VERSION}", "solargraph-#{Solargraph::VERSION}")
      end

      # @return [String]
      def core_path
        File.join(work_dir, 'core.ser')
      end

      # @param file [String]
      # @return [Array<Solargraph::Pin::Base>, nil]
      def load file
        return nil unless File.file?(file)
        Marshal.load(File.read(file, mode: 'rb'))
      rescue StandardError => e
        Solargraph.logger.warn "Failed to load cached file #{file}: [#{e.class}] #{e.message}"
        FileUtils.rm_f file
        nil
      end

      # @param file [String]
      # @param pins [Array<Pin::Base>]
      # @return [void]
      def save file, pins
        base = File.dirname(file)
        FileUtils.mkdir_p base unless File.directory?(base)
        ser = Marshal.dump(pins)
        File.write file, ser, mode: 'wb'
        logger.debug { "Cache#save: Saved #{pins.length} pins to #{file}" }
      end

      def has_core?
        File.file?(core_path)
      end

      def cache_core(out: $stderr)
        RbsMap::CoreMap.new.cache_core(out: out)
      end

      # @return [Array<Pin::Base>]
      def load_core
        load(core_path)
      end

      # @param pins [Array<Pin::Base>]
      # @return [void]
      def serialize_core pins, out: $stderr
        save(core_path, pins)
      end

      def stdlib_path
        File.join(work_dir, 'stdlib')
      end

      def stdlib_require_path require
        File.join(stdlib_path, "#{require}.ser")
      end

      # @param require [String]
      # @return [Array<Pin::Base>]
      def load_stdlib_require require
        load(stdlib_require_path(require))
      end

      def serialize_stdlib_require require, pins
        save(stdlib_require_path(require), pins)
      end
    end
  end
end
