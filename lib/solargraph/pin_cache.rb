require 'fileutils'
require 'rbs'

module Solargraph
  module PinCache
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

      def yardoc_path gemspec
        File.join(base_dir, "yard-#{YARD::VERSION}", "#{gemspec.name}-#{gemspec.version}.yardoc")
      end

      def stdlib_path
        File.join(work_dir, 'stdlib')
      end

      def stdlib_require_path require
        File.join(stdlib_path, "#{require}.ser")
      end

      def deserialize_stdlib_require require
        load(stdlib_require_path(require))
      end

      def serialize_stdlib_require require, pins
        save(stdlib_require_path(require), pins)
      end

      def core_path
        File.join(work_dir, 'core.ser')
      end

      def deserialize_core
        load(core_path)
      end

      def serialize_core pins
        save(core_path, pins)
      end

      def yard_gem_path gemspec
        File.join(work_dir, 'yard', "#{gemspec.name}-#{gemspec.version}.ser")
      end

      def deserialize_yard_gem(gemspec)
        load(yard_gem_path(gemspec))
      end

      def serialize_yard_gem(gemspec, pins)
        save(yard_gem_path(gemspec), pins)
      end

      def has_yard?(gemspec)
        exist?(yard_gem_path(gemspec))
      end

      def rbs_collection_path(gemspec, hash)
        File.join(work_dir, 'rbs', "#{gemspec.name}-#{gemspec.version}-#{hash || 0}.ser")
      end

      def rbs_collection_path_prefix(gemspec)
        File.join(work_dir, 'rbs', "#{gemspec.name}-#{gemspec.version}-")
      end

      def deserialize_rbs_collection_gem(gemspec, hash)
        load(rbs_collection_path(gemspec, hash))
      end

      def serialize_rbs_collection_gem(gemspec, hash, pins)
        save(rbs_collection_path(gemspec, hash), pins)
      end

      def combined_path(gemspec, hash)
        File.join(work_dir, 'combined', "#{gemspec.name}-#{gemspec.version}-#{hash || 0}.ser")
      end

      def combined_path_prefix(gemspec)
        File.join(work_dir, 'combined', "#{gemspec.name}-#{gemspec.version}-")
      end

      def serialize_combined_gem(gemspec, hash, pins)
        save(combined_path(gemspec, hash), pins)
      end

      def deserialize_combined_gem gemspec, hash
        load(combined_path(gemspec, hash))
      end

      def has_rbs_collection?(gemspec, hash)
        exist?(rbs_collection_path(gemspec, hash))
      end

      def uncache_core
        uncache(core_path)
      end

      def uncache_stdlib
        uncache(stdlib_path)
      end

      def uncache_gem(gemspec, out: nil)
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
      # @return [Array<Solargraph::Pin::Base>, nil]
      def load file
        return nil unless File.file?(file)
        Marshal.load(File.read(file, mode: 'rb'))
      rescue StandardError => e
        Solargraph.logger.warn "Failed to load cached file #{file}: [#{e.class}] #{e.message}"
        FileUtils.rm_f file
        nil
      end

      def exist? *path
        File.file? join(*path)
      end

      # @param path [Array<String>]
      # @param pins [Array<Pin::Base>]
      # @return [void]
      def save file, pins
        base = File.dirname(file)
        FileUtils.mkdir_p base unless File.directory?(base)
        ser = Marshal.dump(pins)
        File.write file, ser, mode: 'wb'
        logger.debug { "Cache#save: Saved #{pins.length} pins to #{file}" }
      end

      # @return [void]
      # @param path_segments [Array<String>]
      def uncache *path_segments, out: nil
        path = File.join(*path_segments)
        if File.exist?(path)
          FileUtils.rm_rf path, secure: true
          out.puts "Clearing pin cache in #{path}" unless out.nil?
        end
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
    end
  end
end
