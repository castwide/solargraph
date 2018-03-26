module Solargraph
  class Workspace
    autoload :Config, 'solargraph/workspace/config'

    # @return [String]
    attr_reader :directory

    def initialize directory
      @directory = directory
      load_sources unless directory.nil?
    end

    # @return [Solargraph::Workspace::Config]
    def config reload = false
      @config = Solargraph::Workspace::Config.new(directory) if @config.nil? or reload
      @config
    end

    # Load a new file into the workspace. The file will not be loaded if the
    # workspace is configured to exclude it.
    #
    def handle_created filename
      return unless config(true).calculated.include?(filename)
      if has_file?(filename)
        STDERR.puts "Handle error: loaded file already exists in workspace"
      else
        src = Solargraph::Source.load(filename)
        source_hash[filename] = src
      end
    end

    # Update a changed file in the workspace. The file will be ignored if the
    # workspace is configured to exxlude it.
    #
    def handle_changed filename
      return unless config.calculated.include?(filename)
      if has_file?(filename)
        source_hash[filename].overwrite(File.read(filename))
      else
        STDERR.puts "Handle error: changed file does not exist in workspace"
      end
    end

    # Remove a file from the workspace. The file will not be removed if the
    # file still exists and the workspace is configured to include it.
    #
    def handle_deleted filename
      return if config(true).calculated.include?(filename)
      # @todo This method PROBABLY doesn't care if the file is actually here
      source_hash.delete filename
    end

    # Merge the source
    #
    # @param source [Solargraph::Source]
    def merge source
      return unless config(true).calculated.include?(source.filename)
      source_hash[source.filename] = source
    end

    # @todo Figure out the arch
    def remove source
      return if config(true).calculated.include?(source.filename)
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

    def has_source? source
      source_hash.has_value?(source)
    end

    def has_file? filename
      source_hash.has_key?(filename)
    end

    def source filename
      source_hash[filename]
    end

    # @todo This might be inappropriate. Look into changing the source
    # in place instead of replacing the value.
    # @param source [Solargraph::Source]
    def update source
      source_hash[source.filename] = source if source_hash.has_key?(filename)
    end

    def stime
      return nil if source_hash.empty?
      source_hash.values.sort{|a, b| a.stime <=> b.stime}.last.stime
    end

    private

    # @return [Hash<String, Solargraph::Source>]
    def source_hash
      @source_hash ||= {}
    end

    def load_sources
      source_hash.clear
      config.calculated.each do |filename|
        src = Solargraph::Source.load(filename)
        source_hash[filename] = src
      end
    end
  end
end
