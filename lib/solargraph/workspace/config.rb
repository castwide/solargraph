# frozen_string_literal: true

require 'yaml'

module Solargraph
  class Workspace
    # Configuration data for a workspace.
    #
    class Config
      # The maximum number of files that can be added to a workspace.
      # The workspace's .solargraph.yml can override this value.
      MAX_FILES = 5000

      # @return [String]
      attr_reader :directory

      # @todo Need to validate config
      # @return [Hash{String => undefined, nil}]
      attr_reader :raw_data

      # @param directory [String]
      def initialize directory = ''
        @directory = File.absolute_path(directory)
        @raw_data = config_data
        included
        excluded
      end

      # An array of files included in the workspace (before calculating excluded files).
      #
      # @return [Array<String>]
      def included
        return [] if directory.empty? || directory == '*'
        @included ||= process_globs(@raw_data['include'])
      end

      # An array of files excluded from the workspace.
      #
      # @return [Array<String>]
      def excluded
        return [] if directory.empty? || directory == '*'
        @excluded ||= process_exclusions(@raw_data['exclude'])
      end

      # @param filename [String]
      def allow? filename
        filename = File.absolute_path(filename, directory)
        filename.start_with?(directory) &&
          !excluded.include?(filename) &&
          excluded_directories.none? { |d| filename.start_with?(d) }
      end

      # The calculated array of (included - excluded) files in the workspace.
      #
      # @return [Array<String>]
      def calculated
        unless @calculated || directory.empty? || directory == '*'
          Solargraph.logger.info "Indexing workspace files in #{directory}"
        end
        @calculated ||= included - excluded
      end

      # An array of domains configured for the workspace.
      # A domain is a namespace that the ApiMap should include in the global
      # namespace. It's typically used to identify available DSLs.
      #
      # @return [Array<String>]
      def domains
        validated_array('domains')
      end

      # An array of required paths to add to the workspace.
      #
      # @return [Array<String>]
      def required
        validated_array('require')
      end

      # An array of load paths for required paths.
      #
      # @return [Array<String>]
      def require_paths
        validated_array('require_paths')
      end

      # An array of reporters to use for diagnostics.
      #
      # @return [Array<String>]
      def reporters
        validated_array('reporters')
      end

      # A hash of options supported by the formatter
      #
      # @return [Hash]
      def formatter
        value = raw_data['formatter']
        return {} if value.nil?
        return value if value.is_a?(Hash)
        raise InvalidConfigError, invalid_message('formatter', 'a hash', value)
      end

      # An array of plugins to require.
      #
      # @return [Array<String>]
      def plugins
        validated_array('plugins')
      end

      # The maximum number of files to parse from the workspace.
      #
      # @return [Integer]
      def max_files
        value = raw_data['max_files']
        return MAX_FILES if value.nil?
        return value if value.is_a?(Integer)
        raise InvalidConfigError, invalid_message('max_files', 'an integer', value)
      end

      # @return [Hash{Symbol => Symbol}]
      def type_checker_rules
        # @type [Hash{String => String}]
        raw_rules = raw_data.fetch('type_checker', {}).fetch('rules', {})
        raw_rules.to_h do |k, v|
          [k.to_sym, v.to_sym]
        end
      end

      private

      # Read an array-valued .solargraph.yml key. A key with no value at
      # all means "none", but a value of the wrong type is a mistake the
      # user needs to hear about rather than have silently discarded.
      #
      # @param key [String]
      # @raise [InvalidConfigError] if the value is not an array
      # @return [Array<String>]
      def validated_array key
        value = raw_data[key]
        return [] if value.nil?
        return value if value.is_a?(Array)
        raise InvalidConfigError, invalid_message(key, 'an array', value)
      end

      # @param key [String]
      # @param expected [String] a description of the type the key requires
      # @param value [Object]
      # @return [String]
      def invalid_message key, expected, value
        "Invalid .solargraph.yml: #{key} must be #{expected}, but was #{value.inspect}"
      end

      # @return [String]
      def global_config_path
        ENV['SOLARGRAPH_GLOBAL_CONFIG'] ||
          File.join(Dir.home, '.config', 'solargraph', 'config.yml')
      end

      # @return [String]
      def workspace_config_path
        return '' if @directory.empty?
        File.join(@directory, '.solargraph.yml')
      end

      # @return [Hash{String => undefined}]
      def config_data
        workspace_config = read_config(workspace_config_path)
        global_config = read_config(global_config_path)

        defaults = default_config
        defaults.merge({ 'exclude' => [] }) unless workspace_config.nil?

        defaults
          .merge(global_config || {})
          .merge(workspace_config || {})
      end

      # Read a .solargraph yaml config
      #
      # @param config_path [String]
      # @return [Hash{String => Array, Hash, Integer}, nil]
      def read_config config_path = ''
        return nil if config_path.empty?
        return nil unless File.file?(config_path)
        YAML.safe_load_file(config_path)
      end

      # @return [Hash{String => Array, Hash, Integer}]
      def default_config
        {
          'include' => ['Rakefile', 'Gemfile', '*.gemspec', './**/*.rb'],
          'exclude' => ['spec/**/*', 'test/**/*', 'vendor/**/*', '.bundle/**/*'],
          'require' => [],
          'domains' => [],
          'reporters' => %w[rubocop require_not_found],
          'formatter' => {
            'rubocop' => {
              'cops' => 'safe',
              'except' => [],
              'only' => [],
              'extra_args' => []
            }
          },
          'type_checker' => {
            'rules' => {}
          },
          'require_paths' => [],
          'plugins' => [],
          'max_files' => MAX_FILES
        }
      end

      # Get an array of files from the provided globs.
      #
      # @param globs [Array<String>]
      # @return [Array<String>]
      def process_globs globs
        globs.flat_map do |glob|
          Dir[File.absolute_path(glob, directory)]
            .map { |f| f.gsub('\\', '/') }
            .select { |f| File.file?(f) }
        end
      end

      # Modify the included files based on excluded directories and get an
      # array of additional files to exclude.
      #
      # @param globs [Array<String>]
      # @return [Array<String>]
      def process_exclusions globs
        remainder = globs.select do |glob|
          if glob_is_directory?(glob)
            exdir = File.absolute_path(glob_to_directory(glob), directory)
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
        File.directory?(glob) || File.directory?(glob_to_directory(glob))
      end

      # Translate a glob to a base directory if applicable
      #
      # @example
      #   glob_to_directory('path/to/dir/**/*') # => 'path/to/dir'
      #
      # @param glob [String]
      # @return [String]
      def glob_to_directory glob
        glob.gsub(%r{(/\*|/\*\*/\*\*?)$}, '')
      end

      # @return [Array<String>]
      def excluded_directories
        # @type [Array<String>]
        excluded = @raw_data['exclude']
        excluded
          .select { |g| glob_is_directory?(g) }
          .map { |g| File.absolute_path(glob_to_directory(g), directory) }
      end
    end
  end
end
