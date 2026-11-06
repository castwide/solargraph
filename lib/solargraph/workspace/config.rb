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

      # Per-key doc comment for `solargraph config`'s generated YAML
      # (see .commented_yaml) - a key missing here gets no comment.
      #
      # @return [Hash{String => Array<String>}]
      CONFIG_DOCS = {
        'include' => [
          'Files to include in the workspace, as glob patterns relative to',
          'this directory.'
        ],
        'exclude' => [
          'Files to exclude from the workspace, as glob patterns (checked',
          'after include, so an excluded file stays excluded).'
        ],
        'require' => ['Paths to require before indexing the workspace.'],
        'domains' => [
          'Namespaces to include in the global namespace - e.g. to expose a',
          "DSL's methods without qualifying them."
        ],
        'reporters' => ['Diagnostics reporters to run - see `solargraph reporters`.'],
        'formatter' => ['Options for diagnostics reporters that support them.'],
        'type_checker' => [
          'Per-rule overrides for `solargraph typecheck --level <level>` -',
          'see lib/solargraph/type_checker/rules.rb for the current list',
          'of rule names. Each value is a level name (normal, typed,',
          'strict, strong, alpha) the rule starts reporting at instead',
          'of its default.'
        ],
        'require_paths' => ['Load paths for the paths listed in require above.'],
        'plugins' => ['Plugins to require - see https://solargraph.org/guides/plugins'],
        'max_files' => ['Maximum number of files Solargraph will index in this workspace.'],
        'extensions' => [
          'solargraph-*-ext gems to require automatically. Populated by',
          '`solargraph config`; pass --no-extensions to skip.'
        ]
      }.freeze

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
      # @sg-ignore Need to validate config
      def domains
        raw_data['domains']
      end

      # An array of required paths to add to the workspace.
      #
      # @return [Array<String>]
      # @sg-ignore Need to validate config
      def required
        raw_data['require']
      end

      # An array of load paths for required paths.
      #
      # @sg-ignore Need to validate config
      # @return [Array<String>]
      # @sg-ignore Need to validate config
      def require_paths
        raw_data['require_paths'] || []
      end

      # An array of reporters to use for diagnostics.
      #
      # @sg-ignore Need to validate config
      # @return [Array<String>]
      def reporters
        raw_data['reporters']
      end

      # A hash of options supported by the formatter
      #
      # @sg-ignore Need to validate config
      # @return [Hash]
      def formatter
        raw_data['formatter']
      end

      # An array of plugins to require.
      #
      # @sg-ignore Need to validate config
      # @return [Array<String>]
      def plugins
        raw_data['plugins']
      end

      # The maximum number of files to parse from the workspace.
      #
      # @sg-ignore Need to validate config
      # @return [Integer]
      def max_files
        raw_data['max_files']
      end

      # @return [Hash{Symbol => Symbol}]
      def type_checker_rules
        # @type [Hash{String => String}]
        raw_rules = raw_data.fetch('type_checker', {}).fetch('rules', {})
        raw_rules.to_h do |k, v|
          [k.to_sym, v.to_sym]
        end
      end

      class << self
        # Render config data as YAML, with a doc comment from
        # CONFIG_DOCS above each top-level key.
        #
        # @param conf [Hash{String => undefined}]
        # @return [String]
        def commented_yaml conf
          conf.map do |key, value|
            comment = CONFIG_DOCS.fetch(key, []).map { |line| "# #{line}" }.join("\n")
            # @sg-ignore Psych.dump's RBS also misreads a positional Hash arg as kwargs
            yaml = YAML.dump({ key => value }).sub(/\A---\n/, '')
            [comment, yaml].reject(&:empty?).join("\n")
          end.join("\n")
        end
      end

      private

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
          'max_files' => MAX_FILES,
          'extensions' => []
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
