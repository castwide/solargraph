require 'thread'

module Solargraph
  class Workspace
    autoload :Config, 'solargraph/workspace/config'

    # @return [String]
    attr_reader :directory

    def initialize directory
      @directory = directory
      @load_semaphore = Mutex.new
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
        source_hash[filename] = :loading
      end
      return if source_hash.empty?
      finished = false
      config.calculated.each do |filename|
        Thread.new do
          source = Solargraph::Source.load(filename)
          @load_semaphore.synchronize do
            source_hash[filename] = source
          end
        end
      end
      until finished
        @load_semaphore.synchronize do
          finished = true unless source_hash.values.any?{|s| s == :loading}
        end
        sleep 0.01
      end
    end
  end
end
