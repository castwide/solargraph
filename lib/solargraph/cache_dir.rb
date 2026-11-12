# frozen_string_literal: true

require 'fileutils'
require 'rbs'

module Solargraph
  module CacheDir
    module_function

    # The base directory for cached YARD documentation and serialized pins.
    #
    # @return [String]
    def base_dir
      ENV['SOLARGRAPH_CACHE'] ||
        (ENV['XDG_CACHE_HOME'] ? File.join(ENV['XDG_CACHE_HOME'], 'solargraph') : nil) ||
        File.join(Dir.home, '.cache', 'solargraph')
    end

    # The working directory for the current Ruby, RBS, and Solargraph versions.
    #
    # @return [String]
    def work_dir
      File.join(base_dir, "ruby-#{RUBY_VERSION}", "rbs-#{RBS::VERSION}", "solargraph-#{Solargraph::VERSION}")
    end

    # The gem directory for a set of plugins. Plugins can change the pins
    # mapped from gem source, so each set of plugin versions gets its own.
    #
    # @param plugin_versions [Hash{String => String, nil}] Solargraph plugin
    #   gem name => version, nil when the plugin was not loaded from a gem
    #   (see {Workspace#plugin_versions})
    # @return [String]
    def gem_dir plugin_versions = {}
      return File.join(work_dir, 'gems') if plugin_versions.empty?
      key = plugin_versions.sort.map { |name, version| [name, version].compact.join('-') }.join('+')
      File.join(work_dir, "gems-#{key.tr(File::SEPARATOR, '_')}")
    end

    # The current stdlib directory.
    #
    # @return [String]
    def stdlib_dir
      File.join(work_dir, 'stdlib')
    end

    # The current RBS collection directory.
    #
    # @return [String]
    def rbs_dir
      File.join(work_dir, 'rbs')
    end

    # The directory for the current YARD version.
    #
    # @return [String]
    def yard_dir
      File.join(base_dir, "yard-#{YARD::VERSION}", "yard-activesupport-concern-#{YARD::ActiveSupport::Concern::VERSION}")
    end

    def clear
      FileUtils.rm_rf base_dir
    end
  end
end
