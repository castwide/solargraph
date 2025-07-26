# frozen_string_literal: true

require 'open3'

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

      # Generate require paths from gemspecs if they exist or assume the default
      # lib directory.
      #
      # @param gemspec_file_path [String]
      # @return [Array<String>]
      def require_path_from_gemspec_file gemspec_file_path
        base = File.dirname(gemspec_file_path)
        # HACK: Evaluating gemspec files violates the goal of not running
        #   workspace code, but this is how Gem::Specification.load does it
        #   anyway.
        cmd = ['ruby', '-e',
               "require 'rubygems'; " \
               "require 'json'; " \
               "spec = eval(File.read('#{gemspec_file_path}'), TOPLEVEL_BINDING, '#{gemspec_file_path}'); " \
               'return unless Gem::Specification === spec; ' \
               'puts({name: spec.name, paths: spec.require_paths}.to_json)']
        # @sg-ignore
        o, e, s = Open3.capture3(*cmd)
        if s.success?
          begin
            hash = o && !o.empty? ? JSON.parse(o.split("\n").last) : {}
            return [] if hash.empty?
            hash['paths'].map { |path| File.join(base, path) }
          rescue StandardError => e
            Solargraph.logger.warn "Error reading #{gemspec_file_path}: [#{e.class}] #{e.message}"
            []
          end
        else
          Solargraph.logger.warn "Error reading #{gemspec_file_path}"
          Solargraph.logger.warn e
          []
        end
      end
    end
  end
end
