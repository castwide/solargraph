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

    # The current gem directory. Plugins can change the pins mapped from
    # gem source, so each set of loaded plugin versions gets its own.
    #
    # @return [String]
    def gem_dir
      return File.join(work_dir, 'gems') if plugins.empty?
      key = plugins.sort.map { |name, version| [name, version].compact.join('-') }.join('+')
      File.join(work_dir, "gems-#{key.tr(File::SEPARATOR, '_')}")
    end

    # The plugins loaded in this process, with their gem versions.
    #
    # @return [Hash{String => String, nil}]
    def plugins
      @plugins ||= {}
    end

    # @param name [String] the plugin's require path
    # @return [void]
    def add_plugin name
      # @sg-ignore Unresolved call to name on Gem::BasicSpecification, Hash{String => Gem::BasicSpecification}
      spec = Gem.loaded_specs.each_value.find { |s| s.name == name || s.contains_requirable_file?(name) }
      plugins[name] = spec&.version&.to_s
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
