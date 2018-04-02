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
      @directory = directory
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
    # @param force [Boolean] Merge without checking configuration
    def merge source, force = false
      return unless force or config(true).calculated.include?(source.filename)
      source_hash[source.filename] = source
    end

    # Remove a source from the workspace. The source will not be removed if
    # its file exists and the workspace is configured to include it.
    #
    # @param source [Solargraph::Source]
    # @param force [Boolean] Remove without checking configuration
    def remove source, force = false
      return if !force and config(true).calculated.include?(source.filename)
      # @todo This method PROBABLY doesn't care if the file is actually here
      source_hash.delete source.filename
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
