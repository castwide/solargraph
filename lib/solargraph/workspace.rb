# frozen_string_literal: true

require 'open3'
require 'json'

module Solargraph
  # A workspace consists of the files in a project's directory and the
  # project's configuration. It provides a Source for each file to be used
  # in an associated Library or ApiMap.
  #
  class Workspace
    include Logging

    autoload :Config, 'solargraph/workspace/config'
    autoload :Gemspecs, 'solargraph/workspace/gemspecs'
    autoload :RequirePaths, 'solargraph/workspace/require_paths'

    # @return [String]
    attr_reader :directory

    # @return [Array<String>]
    attr_reader :gemnames
    alias source_gems gemnames

    # @param directory [String]
    # @param config [Config, nil]
    # @param server [Hash]
    def initialize directory = '', config = nil, server = {}
      @directory = directory
      @config = config
      @server = server
      load_sources
      @gemnames = []
      require_plugins
    end

    # The require paths associated with the workspace.
    #
    # @return [Array<String>]
    def require_paths
      # @todo are the semantics of '*' the same as '', meaning 'don't send back any require paths'?
      @require_paths ||= RequirePaths.new(directory_or_nil, config).generate
    end

    # @return [Solargraph::Workspace::Config]
    def config
      @config ||= Solargraph::Workspace::Config.new(directory)
    end

    # @param stdlib_name [String]
    #
    # @return [Array<String>]
    def stdlib_dependencies stdlib_name
      gemspecs.stdlib_dependencies(stdlib_name)
    end

    # @param out [IO, nil] output stream for logging
    # @param gemspec [Gem::Specification]
    # @return [Array<Gem::Specification>]
    def fetch_dependencies gemspec, out: $stderr
      gemspecs.fetch_dependencies(gemspec, out: out)
    end

    # @param require [String] The string sent to 'require' in the code to resolve, e.g. 'rails', 'bundler/require'
    # @return [Array<Gem::Specification>]
    def resolve_require require
      gemspecs.resolve_require(require)
    end

    # Merge the source. A merge will update the existing source for the file
    # or add it to the sources if the workspace is configured to include it.
    # The source is ignored if the configuration excludes it.
    #
    # @param sources [Array<Solargraph::Source>]
    # @return [Boolean] True if the source was added to the workspace
    def merge *sources
      unless directory == '*' || sources.all? { |source| source_hash.key?(source.filename) }
        # Reload the config to determine if a new source should be included
        @config = Solargraph::Workspace::Config.new(directory)
      end

      includes_any = false
      sources.each do |source|
        if directory == "*" || config.calculated.include?(source.filename)
          source_hash[source.filename] = source
          includes_any = true
        end
      end

      includes_any
    end

    # Remove a source from the workspace. The source will not be removed if
    # its file exists and the workspace is configured to include it.
    #
    # @param filename [String]
    # @return [Boolean] True if the source was removed from the workspace
    def remove filename
      return false unless source_hash.key?(filename)
      source_hash.delete filename
      true
    end

    # @return [Array<String>]
    def filenames
      source_hash.keys
    end

    # @return [Array<Solargraph::Source>]
    def sources
      source_hash.values
    end

    # @param filename [String]
    # @return [Boolean]
    def has_file? filename
      source_hash.key?(filename)
    end

    # Get a source by its filename.
    #
    # @param filename [String]
    # @return [Solargraph::Source]
    def source filename
      source_hash[filename]
    end

    # True if the path resolves to a file in the workspace's require paths.
    #
    # @param path [String]
    # @return [Boolean]
    def would_require? path
      require_paths.each do |rp|
        full = File.join rp, path
        return true if File.file?(full) || File.file?(full << ".rb")
      end
      false
    end

    # True if the workspace contains at least one gemspec file.
    #
    # @return [Boolean]
    def gemspec?
      !gemspec_files.empty?
    end

    # Get an array of all gemspec files in the workspace.
    #
    # @return [Array<String>]
    def gemspec_files
      return [] if directory.empty? || directory == '*'
      @gemspec_files ||= Dir[File.join(directory, '**/*.gemspec')].select do |gs|
        config.allow? gs
      end
    end

    # @return [String, nil]
    def rbs_collection_path
      @gem_rbs_collection ||= read_rbs_collection_path
    end

    # @return [String, nil]
    def rbs_collection_config_path
      @rbs_collection_config_path ||= begin
        unless directory.empty? || directory == '*'
          yaml_file = File.join(directory, 'rbs_collection.yaml')
          yaml_file if File.file?(yaml_file)
        end
      end
    end

    # @param name [String]
    # @param version [String, nil]
    #
    # @return [Gem::Specification, nil]
    def find_gem name, version = nil
      gemspecs.find_gem(name, version)
    end

    # @return [Array<Gem::Specification>]
    def all_gemspecs_from_bundle
      gemspecs.all_gemspecs_from_bundle
    end

    # Synchronize the workspace from the provided updater.
    #
    # @param updater [Source::Updater]
    # @return [void]
    def synchronize! updater
      source_hash[updater.filename] = source_hash[updater.filename].synchronize(updater)
    end

    # @return [String]
    def command_path
      server['commandPath'] || 'solargraph'
    end

    # @return [String, nil]
    def directory_or_nil
      return nil if directory.empty? || directory == '*'
      directory
    end

    # @return [Solargraph::Workspace::Gemspecs]
    def gemspecs
      @gemspecs ||= Solargraph::Workspace::Gemspecs.new(directory_or_nil)
    end

    private

    # The language server configuration (or an empty hash if the workspace was
    # not initialized from a server).
    #
    # @return [Hash]
    attr_reader :server

    # @return [Hash{String => Solargraph::Source}]
    def source_hash
      @source_hash ||= {}
    end

    # @return [void]
    def load_sources
      source_hash.clear
      unless directory.empty? || directory == '*'
        size = config.calculated.length
        raise WorkspaceTooLargeError, "The workspace is too large to index (#{size} files, #{config.max_files} max)" if config.max_files > 0 and size > config.max_files
        config.calculated.each do |filename|
          begin
            source_hash[filename] = Solargraph::Source.load(filename)
          rescue Errno::ENOENT => e
            Solargraph.logger.warn("Error loading #{filename}: [#{e.class}] #{e.message}")
          end
        end
      end
    end

    # @return [void]
    def require_plugins
      config.plugins.each do |plugin|
        begin
          require plugin
        rescue LoadError
          Solargraph.logger.warn "Failed to load plugin '#{plugin}'"
        end
      end
    end

    # @return [String, nil]
    def read_rbs_collection_path
      return unless rbs_collection_config_path

      path = YAML.load_file(rbs_collection_config_path)&.fetch('path')
      # make fully qualified
      File.expand_path(path, directory)
    end
  end
end
