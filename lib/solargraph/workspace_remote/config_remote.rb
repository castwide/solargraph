module Solargraph
  class Workspace
    class ConfigRemote < Solargraph::Workspace::Config

      def initialize workspace = nil, files = nil
      	@files = files
        @workspace = workspace
        include_globs = ['**/*.rb', '**.rb']
        exclude_globs = [
          'spec/**/*', 'spec/**',
          'test/**/*', 'test/**',
          'vendor/**/*', 'vendor/**',
          '.bundle/**/*', '.bundle/**'
        ]
        @raw_data ||= {}
        @raw_data['include'] ||= include_globs
        @raw_data['exclude'] ||= exclude_globs
        @raw_data['require'] ||= []
        @raw_data['domains'] ||= []
        @raw_data['reporters'] ||= %w[rubocop require_not_found]
        @raw_data['plugins'] ||= []
        @raw_data['max_files'] ||= Workspace::MAX_WORKSPACE_SIZE
        included
        excluded
      end

      # An array of files included in the workspace (before calculating excluded files).
      #
      # @return [Array<String>]
      def included
      	return @included unless @included.nil?
        @included = []
        return @included if @files.nil?
        @files.each do |file|
        	@included.push(file) if file_included(file, @raw_data['include'])
        end
        @included
      end

      def file_included file, include_globs
      	file = file.gsub(/^[^:]+:\/\/\/?/, "")
      	include_globs.each do |include_glob|
      		return true if File.fnmatch(include_glob, file)
      	end
      	return false
      end

      # An array of files excluded from the workspace.
      #
      # @return [Array<String>]
      def excluded
      	return @excluded unless @excluded.nil?
        @excluded = []
        return @excluded if @files.nil?
        @files.each do |file|
        	@excluded.push(file) if file_excluded(file, @raw_data['exclude'])
        end
        @excluded
      end

      def file_excluded file, exclude_globs
      	file = file.gsub(/^[^:]+:\/\/\/?/, "")
      	exclude_globs.each do |exclude_glob|
      		return true if File.fnmatch(exclude_glob, file)
      	end
      	return false
      end

    end
  end
end