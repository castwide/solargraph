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

    # What to require to load {plugins} again in another process, such as
    # the cache subprocess, so that it writes to the same {gem_dir}.
    #
    # @return [Array<String>]
    def plugin_requires
      @plugin_requires ||= []
    end

    # @param name [String] the plugin's require path
    # @return [void]
    def add_plugin name
      # @sg-ignore https://github.com/castwide/solargraph/pull/1415
      spec = Gem.loaded_specs.each_value.find { |s| s.name == name || s.contains_requirable_file?(name) }
      plugins[spec&.name || name] = spec&.version&.to_s
      plugin_requires.push name unless plugin_requires.include?(name)
    end

    # Record the gem that defines a convention, so a plugin loaded by a
    # plain require still gets its own gem cache directory.
    #
    # @param convention [Class<Convention::Base>]
    # @return [void]
    def add_convention convention
      name = convention.name
      return if name.nil?
      file = Object.const_source_location(name)&.first
      return if file.nil?
      # @sg-ignore https://github.com/castwide/solargraph/pull/1415
      spec = Gem.loaded_specs.each_value.find { |s| file.start_with?(File.join(s.full_gem_path, '')) }
      # @sg-ignore https://github.com/castwide/solargraph/pull/1415
      return if spec.nil? || spec.name == 'solargraph'
      # @sg-ignore https://github.com/castwide/solargraph/pull/1415
      plugins[spec.name] = spec.version.to_s
      # @sg-ignore https://github.com/castwide/solargraph/pull/1415
      plugin_requires.push spec.name unless plugin_requires.include?(spec.name)
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
