require 'yard-activesupport-concern'
require 'fileutils'
require 'pathname' # @todo Required by RBS but not loaded in some use cases
require 'rbs'

module Solargraph
  class PinCache
    include Logging

    attr_reader :rbs_collection_path, :rbs_collection_config_path

    # Combined pins already deserialized in this process, shared across
    # instances and keyed by the RBS cache key as well as the gem, so two
    # configurations resolving the same gem differently cannot collide.
    #
    # @return [Hash{Array(String, Gem::Version, String) => Array<Pin::Base>}]
    def self.all_combined_pins_in_memory
      @all_combined_pins_in_memory ||= {}
    end

    # @param rbs_collection_path [String, nil]
    # @param rbs_collection_config_path [String, nil]
    def initialize rbs_collection_path:, rbs_collection_config_path:
      @rbs_collection_path = rbs_collection_path
      @rbs_collection_config_path = rbs_collection_config_path
    end

    # Which RBS source this configuration resolves the gem to, and so which
    # cache entry it names.
    #
    # @param gemspec [Gem::Specification]
    # @return [String]
    def cache_key_for gemspec
      RbsMap.from_gemspec(gemspec, rbs_collection_path, rbs_collection_config_path).cache_key
    end

    # @param gemspec [Gem::Specification]
    # @return [Boolean]
    def cached? gemspec
      self.class.has_combined?(gemspec, cache_key_for(gemspec))
    end

    # @param gemspec [Gem::Specification]
    # @return [Array<Pin::Base>, nil]
    def deserialize_combined_gem gemspec
      key = memory_key(gemspec)
      return self.class.all_combined_pins_in_memory[key] if self.class.all_combined_pins_in_memory.key?(key)

      cached = self.class.deserialize_combined_gem(gemspec, cache_key_for(gemspec))
      self.class.all_combined_pins_in_memory[key] = cached if cached
      cached
    end

    # @param gemspec [Gem::Specification]
    # @param pins [Array<Pin::Base>]
    # @return [void]
    def serialize_combined_gem gemspec, pins
      key = memory_key(gemspec)
      self.class.serialize_combined_gem(gemspec, cache_key_for(gemspec), pins)
      self.class.all_combined_pins_in_memory[key] = pins
    end

    # @param gemspec [Gem::Specification]
    # @return [Array<Pin::Base>, nil]
    def deserialize_rbs_collection_gem gemspec
      self.class.deserialize_rbs_collection_gem(gemspec, cache_key_for(gemspec))
    end

    # @param gemspec [Gem::Specification]
    # @param pins [Array<Pin::Base>]
    # @return [void]
    def serialize_rbs_collection_gem gemspec, pins
      self.class.serialize_rbs_collection_gem(gemspec, cache_key_for(gemspec), pins)
    end

    # @param gemspec [Gem::Specification]
    # @return [Boolean]
    def has_rbs_collection? gemspec
      self.class.has_rbs_collection?(gemspec, cache_key_for(gemspec))
    end

    # Drops the on-disk entries and the in-memory one, which the class-level
    # version cannot reach.
    #
    # @param gemspec [Gem::Specification]
    # @param out [IO, StringIO, nil]
    # @return [void]
    def uncache_gem gemspec, out: nil
      self.class.uncache_gem(gemspec, out: out)
      self.class.all_combined_pins_in_memory.delete(memory_key(gemspec))
    end

    private

    # @param gemspec [Gem::Specification]
    # @return [Array(String, Gem::Version, String)]
    def memory_key gemspec
      [gemspec.name, gemspec.version, cache_key_for(gemspec)]
    end

    class << self
      include Logging

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

      # The working directory for the current Ruby, RBS, and Solargraph versions.
      #
      # @return [String]
      def work_dir
        # The directory is not stored in a variable so it can be overridden
        # in specs.
        File.join(base_dir, "ruby-#{RUBY_VERSION}", "rbs-#{RBS::VERSION}", "solargraph-#{Solargraph::VERSION}")
      end

      # @param gemspec [Gem::Specification]
      # @return [String]
      def yardoc_path gemspec
        File.join(base_dir,
                  "yard-#{YARD::VERSION}",
                  "yard-activesupport-concern-#{YARD::ActiveSupport::Concern::VERSION}",
                  "#{gemspec.name}-#{gemspec.version}.yardoc")
      end

      # @return [String]
      def stdlib_path
        File.join(work_dir, 'stdlib')
      end

      # @param require [String]
      # @return [String]
      def stdlib_require_path require
        File.join(stdlib_path, "#{require}.ser")
      end

      # @param require [String]
      # @return [Array<Pin::Base>, nil]
      def deserialize_stdlib_require require
        load(stdlib_require_path(require))
      end

      # @param require [String]
      # @param pins [Array<Pin::Base>]
      # @return [void]
      def serialize_stdlib_require require, pins
        save(stdlib_require_path(require), pins)
      end

      # @return [String]
      def core_path
        File.join(work_dir, 'core.ser')
      end

      # @return [Array<Pin::Base>, nil]
      def deserialize_core
        load(core_path)
      end

      # @param pins [Array<Pin::Base>]
      # @return [void]
      def serialize_core pins
        save(core_path, pins)
      end

      # @param gemspec [Gem::Specification]
      # @return [String]
      def yard_gem_path gemspec
        File.join(work_dir, 'yard', "#{gemspec.name}-#{gemspec.version}.ser")
      end

      # @param gemspec [Gem::Specification]
      # @return [Array<Pin::Base>, nil]
      def deserialize_yard_gem gemspec
        load(yard_gem_path(gemspec))
      end

      # @param gemspec [Gem::Specification]
      # @param pins [Array<Pin::Base>]
      # @return [void]
      def serialize_yard_gem gemspec, pins
        save(yard_gem_path(gemspec), pins)
      end

      # @param gemspec [Gem::Specification]
      # @return [Boolean]
      def has_yard? gemspec
        exist?(yard_gem_path(gemspec))
      end

      # @param gemspec [Gem::Specification]
      # @param hash [String, nil]
      # @return [String]
      def rbs_collection_gem_path gemspec, hash
        File.join(work_dir, 'rbs', "#{gemspec.name}-#{gemspec.version}-#{hash || 0}.ser")
      end

      # @param gemspec [Gem::Specification]
      # @return [String]
      def rbs_collection_path_prefix gemspec
        File.join(work_dir, 'rbs', "#{gemspec.name}-#{gemspec.version}-")
      end

      # @param gemspec [Gem::Specification]
      # @param hash [String, nil]
      # @return [Array<Pin::Base>, nil]
      def deserialize_rbs_collection_gem gemspec, hash
        load(rbs_collection_gem_path(gemspec, hash))
      end

      # @param gemspec [Gem::Specification]
      # @param hash [String, nil]
      # @param pins [Array<Pin::Base>]n
      # @return [void]
      def serialize_rbs_collection_gem gemspec, hash, pins
        save(rbs_collection_gem_path(gemspec, hash), pins)
      end

      # @param gemspec [Gem::Specification]
      # @param hash [String, nil]
      # @return [String]
      def combined_path gemspec, hash
        File.join(work_dir, 'combined', "#{gemspec.name}-#{gemspec.version}-#{hash || 0}.ser")
      end

      # @param gemspec [Gem::Specification]
      # @return [String]
      def combined_path_prefix gemspec
        File.join(work_dir, 'combined', "#{gemspec.name}-#{gemspec.version}-")
      end

      # @param gemspec [Gem::Specification]
      # @param hash [String, nil]
      # @param pins [Array<Pin::Base>]
      # @return [void]
      def serialize_combined_gem gemspec, hash, pins
        save(combined_path(gemspec, hash), pins)
      end

      # @param gemspec [Gem::Specification]
      # @param hash [String, nil]
      # @return [Array<Pin::Base>, nil]
      def deserialize_combined_gem gemspec, hash
        load(combined_path(gemspec, hash))
      end

      # @param gemspec [Gem::Specification]
      # @param hash [String, nil]
      # @return [Boolean]
      def has_rbs_collection? gemspec, hash
        exist?(rbs_collection_gem_path(gemspec, hash))
      end

      # @param gemspec [Gem::Specification]
      # @param hash [String, nil]
      # @return [Boolean]
      def has_combined? gemspec, hash
        exist?(combined_path(gemspec, hash))
      end

      # @return [void]
      def uncache_core
        uncache(core_path)
      end

      # @return [void]
      def uncache_stdlib
        uncache(stdlib_path)
      end

      # @param gemspec [Gem::Specification]
      # @param out [IO, StringIO, nil]
      # @return [void]
      def uncache_gem gemspec, out: nil
        uncache(yardoc_path(gemspec), out: out)
        uncache_by_prefix(rbs_collection_path_prefix(gemspec), out: out)
        uncache(yard_gem_path(gemspec), out: out)
        uncache_by_prefix(combined_path_prefix(gemspec), out: out)
      end

      # @return [void]
      def clear
        FileUtils.rm_rf base_dir, secure: true
      end

      private

      # @param file [String]
      # @sg-ignore Marshal.load returns Object; we know it's Array<Pin::Base>
      # @return [Array<Solargraph::Pin::Base>, nil]
      def load file
        return nil unless File.file?(file)
        Marshal.load(File.read(file, mode: 'rb'))
      rescue StandardError => e
        Solargraph.logger.warn "Failed to load cached file #{file}: [#{e.class}] #{e.message}"
        FileUtils.rm_f file
        nil
      end

      # @param path [String]
      def exist? *path
        File.file? File.join(*path)
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

      # @param path_segments [Array<String>]
      # @return [void]
      # @param [Object, nil] out
      def uncache *path_segments, out: nil
        path = File.join(*path_segments)
        return unless File.exist?(path)
        FileUtils.rm_rf path, secure: true
        out&.puts "Clearing pin cache in #{path}"
      end

      # @return [void]
      # @param path_segments [Array<String>]
      # @param [Object, nil] out
      def uncache_by_prefix *path_segments, out: nil
        path = File.join(*path_segments)
        glob = "#{path}*"
        out&.puts "Clearing pin cache in #{glob}"
        Dir.glob(glob).each do |file|
          next unless File.file?(file)
          FileUtils.rm_rf file, secure: true
          out&.puts "Clearing pin cache in #{file}"
        end
      end
    end
  end
end
