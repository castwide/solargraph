require 'fileutils'
require 'rbs'

module Solargraph
  module Cache
    class << self
      # The base directory where cached documentation is installed.
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

      # Append the given path to the current cache directory (`work_dir`).
      #
      # @example
      #   Cache.join('date-3.4.1.ser')
      #
      # @param path [Array<String>]
      # @return [String]
      def join *path
        File.join(work_dir, *path)
      end

      # @param path [Array<String>]
      # @return [Array<Solargraph::Pin::Base>, nil]
      def load *path
        file = join(*path)
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

      # @return [Boolean]
      def save *path, pins
        return false if pins.empty?
        file = File.join(work_dir, *path)
        base = File.dirname(file)
        FileUtils.mkdir_p base unless File.directory?(base)
        ser = Marshal.dump(pins)
        File.write file, ser, mode: 'wb'
        true
      end

      # @return [void]
      # @param path [Array<String>]
      def uncache *path
        FileUtils.rm_rf File.join(work_dir, *path), secure: true
      end

      # @return [void]
      def clear
        FileUtils.rm_rf base_dir, secure: true
      end
    end
  end
end
