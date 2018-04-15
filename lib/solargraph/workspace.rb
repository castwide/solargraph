module Solargraph
  # A workspace consists of the files in a project's directory and the
  # project's configuration. It provides a Source for each file to be used
  # in an associated Library or ApiMap.
  #
  class Workspace
    autoload :Config, 'solargraph/workspace/config'

    # @return [String]
    attr_reader :directory

    def initialize directory
      # @todo Convert to an absolute path?
      @directory = directory
      @directory = nil if @directory == ''
      load_sources
    end

    # @return [Solargraph::Workspace::Config]
    def config reload = false
      @config = Solargraph::Workspace::Config.new(directory) if @config.nil? or reload
      @config
    end

    # Merge the source. A merge will update the existing source for the file
    # or add it to the sources if the workspace is configured to include it.
    # The source is ignored if the configuration excludes it.
    #
    # @param source [Solargraph::Source]
    # @return [Boolean] True if the source was added to the workspace
    def merge source
      return false unless config(true).calculated.include?(source.filename)
      source_hash[source.filename] = source
      true
    end

    # Determine whether a file would be merged into the workspace.
    #
    # @param filename [String]
    # @return [Boolean]
    def would_merge? filename
      Solargraph::Workspace::Config.new(directory).calculated.include?(filename)
    end

    # Remove a source from the workspace. The source will not be removed if
    # its file exists and the workspace is configured to include it.
    #
    # @param source [Solargraph::Source]
    # @return [Boolean] True if the source was removed from the workspace
    def remove source
      return false if config(true).calculated.include?(source.filename)
      # @todo This method PROBABLY doesn't care if the file is actually here
      source_hash.delete source.filename
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
    def has_source? source
      source_hash.has_value?(source)
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

    def stime
      return @stime if source_hash.empty?
      @stime = source_hash.values.sort{|a, b| a.stime <=> b.stime}.last.stime
    end

    private

    # @return [Hash<String, Solargraph::Source>]
    def source_hash
      @source_hash ||= {}
    end

    def load_sources
      source_hash.clear
      unless directory.nil?
        config(true).calculated.each do |filename|
          src = Solargraph::Source.load(filename)
          source_hash[filename] = src
        end
      end
      @stime = Time.now
    end
  end
end
