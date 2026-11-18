# frozen_string_literal: true

module Solargraph
  # A workspace consists of the files in a project's directory and the
  # project's configuration. It provides a Source for each file to be used
  # in an associated Library or ApiMap.
  #
  class Workspace
    # Manages determining which gemspecs are available in a workspace
    class RequirePaths
      attr_reader :directory, :config

      # @param directory [String, nil]
      # @param config [Config, nil]
      def initialize directory, config
        @directory = directory
        @config = config
      end

      # Generate require paths from gemspecs if they exist or assume the default
      # lib directory.
      #
      # @return [Array<String>]
      def generate
        result = require_paths_from_gemspec_files
        return configured_require_paths if result.empty?
        result.concat(config.require_paths.map { |p| File.join(directory, p) }) if config
        result
      end

      private

      # @return [Array<String>]
      def require_paths_from_gemspec_files
        results = []
        gemspec_file_paths.each do |gemspec_file_path|
          results.concat require_path_from_gemspec_file(gemspec_file_path)
        end
        results
      end

      # Get an array of all gemspec files in the workspace.
      #
      # @return [Array<String>]
      def gemspec_file_paths
        return [] if directory.nil?
        @gemspec_file_paths ||= Dir[File.join(directory, '**/*.gemspec')].select do |gs|
          config.nil? || config.allow?(gs)
        end
      end

      # Get additional require paths defined in the configuration.
      #
      # @return [Array<String>]
      def configured_require_paths
        return ['lib'] unless directory
        return [File.join(directory, 'lib')] if !config || config.require_paths.empty?
        config.require_paths.map { |p| File.join(directory, p) }
      end

      # Get require paths from a gemspec file by parsing it statically.
      # Gemspecs are never evaluated, so dynamic require paths default to
      # the standard lib directory.
      #
      # @param gemspec_file_path [String]
      # @return [Array<String>]
      def require_path_from_gemspec_file gemspec_file_path
        base = File.dirname(gemspec_file_path)
        Metagem.parse_require_paths(gemspec_file_path)
               .map { |path| File.join(base, path) }
      end
    end
  end
end
