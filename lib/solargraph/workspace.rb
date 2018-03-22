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

    # def reload
    #   @config = Solargraph::Workspace::Config.new(directory)
    #   load_sources unless directory.nil?
    # end

    def load filename
      return unless config(true).calculated.include?(filename)
      if has_file?(filename)
        STDERR.puts "Handle error: appended file already exists in workspace"
      else
        STDERR.puts "Adding a file! #{filename}"
        src = Solargraph::Source.load(filename)
        source_hash[filename] = src
      end
    end

    def remove filename
      return if config(true).calculated.include?(filename)
      source_hash.delete filename
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
