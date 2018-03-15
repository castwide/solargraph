module Solargraph
  class Workspace
    autoload :Config, 'solargraph/workspace/config'

    # @return [String]
    attr_reader :directory

    def initialize directory
      STDERR.puts "The workspace: #{directory}"
      @directory = directory
      load_sources unless directory.nil?
    end

    # @return [Solargraph::Workspace::Config]
    def config
      @config ||= Solargraph::Workspace::Config.new(directory)
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

    # @param source [Solargraph::Source]
    def update source
      source_hash[source.filename] = source if source_hash.has_key?(filename)
    end

    def stime
      source_hash.values.sort{|a, b| a.stime <=> b.stime}.last.stime
    end

    private

    # @return [Hash<String, Solargraph::Source>]
    def source_hash
      @source_hash ||= {}
    end

    def load_sources
      config.calculated.each do |filename|
        STDERR.puts "Loading #{filename}"
        source_hash[filename] = Solargraph::Source.load(filename)
      end
    end
  end
end
