module Solargraph
  # A workspace consists of the files in a project's directory and the
  # project's configuration. It provides a Source for each file to be used
  # in an associated Library or ApiMap.
  #
  class Workspace
    autoload :Config, 'solargraph/workspace/config'

    # @return [String]
    attr_reader :directory

    # @param directory [String]
    def initialize directory = '', config = nil
      @directory = directory
      @config = config
      load_sources
    end

    # @return [Solargraph::Workspace::Config]
    def config
      @config ||= Solargraph::Workspace::Config.new(directory)
    end

    # Merge the source. A merge will update the existing source for the file
    # or add it to the sources if the workspace is configured to include it.
    # The source is ignored if the configuration excludes it.
    #
    # @param source [Solargraph::Source]
    # @return [Boolean] True if the source was added to the workspace
    def merge source
      unless source_hash.has_key?(source.filename)
        # Reload the config to determine if a new source should be included
        @config = Solargraph::Workspace::Config.new(directory)
        return false unless config.calculated.include?(source.filename)
      end
      source_hash[source.filename] = source
      true
    end

    # Determine whether a file would be merged into the workspace.
    #
    # @param filename [String]
    # @return [Boolean]
    def would_merge? filename
      return true if source_hash.include?(filename)
      @config = Solargraph::Workspace::Config.new(directory)
      config.calculated.include?(filename)
    end

    # Remove a source from the workspace. The source will not be removed if
    # its file exists and the workspace is configured to include it.
    #
    # @param filename [String]
    # @return [Boolean] True if the source was removed from the workspace
    def remove filename
      return false unless source_hash.has_key?(filename)
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

    # @return [Boolean]
    def has_file? filename
      source_hash.has_key?(filename)
    end

    # Get a source by its filename.
    #
    # @return [Solargraph::Source]
    def source filename
      source_hash[filename]
    end

    # The require paths associated with the workspace.
    #
    # @return [Array<String>]
    def require_paths
      @require_paths ||= generate_require_paths
    end

    # True if the path resolves to a file in the workspace's require paths.
    #
    # @param path [String]
    # @return [Boolean]
    def would_require? path
      require_paths.each do |rp|
        return true if File.exist?(File.join(rp, "#{path}.rb"))
      end
      false
    end

    # True if the workspace contains at least one gemspec file.
    #
    # @return [Boolean]
    def gemspec?
      !gemspecs.empty?
    end

    # Get an array of all gemspec files in the workspace.
    #
    # @return [Array<String>]
    def gemspecs
      return [] if directory.empty?
      @gemspecs ||= Dir[File.join(directory, '**/*.gemspec')]
    end

    # Synchronize the workspace from the provided updater.
    #
    # @param [Source::Updater]
    # @return [void]
    def synchronize! updater
      source_hash[updater.filename] = source_hash[updater.filename].synchronize(updater)
    end

    private

    # @return [Hash<String, Solargraph::Source>]
    def source_hash
      @source_hash ||= {}
    end

    def load_sources
      source_hash.clear
      unless directory.empty?
        size = config.calculated.length
        raise WorkspaceTooLargeError, "The workspace is too large to index (#{size} files, #{config.max_files} max)" if config.max_files > 0 and size > config.max_files
        config.calculated.each do |filename|
          source_hash[filename] = Solargraph::Source.load(filename)
        end
      end
    end

    def generate_require_paths
      return configured_require_paths if directory.empty? || !gemspec?
      result = []
      gemspecs.each do |file|
        # @todo Evaluating gemspec files violates the goal of not running
        #   workspace code, but this is how Gem::Specification.load does it
        #   anyway.
        begin
           spec = eval(File.read(file), binding, file)
           next unless Gem::Specification === spec
           base = File.dirname(file)
           result.concat spec.require_paths.map{ |path| File.join(base, path) } unless spec.nil?
        rescue
           # Don't die if we have an error during eval-ing a gem spec.
        end
      end
      result.concat config.require_paths
      result.push File.join(directory, 'lib') if result.empty?
      result
    end

    def configured_require_paths
      return ['lib'] if directory.empty?
      return [File.join(directory, 'lib')] if config.require_paths.empty?
      config.require_paths.map{|p| File.join(directory, p)}
    end
  end
end
