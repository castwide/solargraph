require 'yaml'

module Solargraph
  class Workspace
    class Config
      # The maximum number of files that can be added to a workspace.
      # The workspace's .solargraph.yml can override this value.
      MAX_FILES = 5000

      # @return [String]
      attr_reader :workspace

      # @return [Hash]
      attr_reader :raw_data

      # @param workspace [String]
      def initialize workspace = nil
        @workspace = workspace
        include_globs = ['**/*.rb']
        exclude_globs = ['spec/**/*', 'test/**/*', 'vendor/**/*', '.bundle/**/*']
        unless @workspace.nil?
          sfile = File.join(@workspace, '.solargraph.yml')
          if File.file?(sfile)
            @raw_data = YAML.load(File.read(sfile))
            conf = YAML.load(File.read(sfile))
            include_globs = conf['include'] || include_globs
            exclude_globs = conf['exclude'] || []
          end
        end
        @raw_data ||= {}
        @raw_data['include'] ||= include_globs
        @raw_data['exclude'] ||= exclude_globs
        @raw_data['require'] ||= []
        @raw_data['domains'] ||= []
        @raw_data['reporters'] ||= %w[rubocop require_not_found]
        @raw_data['plugins'] ||= []
        @raw_data['max_files'] ||= MAX_FILES
        included
        excluded
      end

      # An array of files included in the workspace (before calculating excluded files).
      #
      # @return [Array<String>]
      def included
        return [] if workspace.nil?
        @included ||= process_globs(@raw_data['include'])
      end

      # An array of files excluded from the workspace.
      #
      # @return [Array<String>]
      def excluded
        return [] if workspace.nil?
        @excluded ||= process_exclusions(@raw_data['exclude'])
      end

      # The calculated array of (included - excluded) files in the workspace.
      #
      # @return [Array<String>]
      def calculated
        @calculated ||= included - excluded
      end

      # An array of domains configured for the workspace.
      # A domain is a namespace that the ApiMap should include in the global
      # namespace. It's typically used to identify available DSLs.
      #
      # @return [Array<String>]
      def domains
        raw_data['domains']
      end

      # An array of required paths to add to the workspace.
      #
      # @return [Array<String>]
      def required
        raw_data['require']
      end

      def require_paths
        raw_data['require_paths'] || []
      end

      # An array of Solargraph plugins to install.
      #
      # @return [Array<String>]
      def plugins
        raw_data['plugins']
      end

      # An array of reporters to use for diagnostics.
      #
      # @return [Array<String>]
      def reporters
        raw_data['reporters']
      end

      # The maximum number of files to parse from the workspace.
      #
      # @return [Integer]
      def max_files
        raw_data['max_files']
      end

      private

      # Get an array of files from the provided globs.
      #
      # @param globs [Array<String>]
      # @return [Array<String>]
      def process_globs globs
        result = []
        globs.each do |glob|
          result.concat Dir[File.join workspace, glob].map{ |f| f.gsub(/\\/, '/') }
        end
        result
      end

      # Modify the included files based on excluded directories and get an
      # array of additional files to exclude.
      #
      # @param globs [Array<String>]
      # @return [Array<String>]
      def process_exclusions globs
        remainder = globs.select do |glob|
          if glob_is_directory?(glob)
            exdir = File.join(workspace, glob_to_directory(glob))
            included.delete_if { |file| file.start_with?(exdir) }
            false
          else
            true
          end
        end
        process_globs remainder
      end

      # True if the glob translates to a whole directory.
      #
      # @example
      #   glob_is_directory?('path/to/dir')       # => true
      #   glob_is_directory?('path/to/dir/**/*)   # => true
      #   glob_is_directory?('path/to/file.txt')  # => false
      #   glob_is_directory?('path/to/*.txt')     # => false
      #
      # @param glob [String]
      # @return [Boolean]
      def glob_is_directory? glob
        File.directory?(glob) or File.directory?(glob_to_directory(glob))
      end

      # Translate a glob to a base directory if applicable
      #
      # @example
      #   glob_to_directory('path/to/dir/**/*') # => 'path/to/dir'
      #
      # @param glob [String]
      # @return [String]
      def glob_to_directory glob
        glob.gsub(/(\/\*|\/\*\*\/\*\*?)$/, '')
      end
    end
  end
end
