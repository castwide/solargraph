module Solargraph
  class Workspace
    # @return [String]
    attr_reader :directory

    def initialize directory
      @directory = directory
      load_sources
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

    def include? filename
      source_hash.has_key?(filename)
    end

    def source filename
      source_hash[filename]
    end

    # @param source [Solargraph::Source]
    def update source
      source_hash[source.filename] = source if source_hash.has_key?(filename)
    end

    private

    # @return [Hash<String, Solargraph::Source>]
    def source_hash
      @source_hash ||= {}
    end

    def load_sources
      config.calculated.each do |filename|
        source_hash[filename] = Solargraph::Source.load(filename)
      end
    end
  end
end
