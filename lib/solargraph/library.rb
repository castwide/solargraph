module Solargraph
  class FileNotFoundError < Exception; end

  class Library
    # @return [Solargraph::Workspace]
    attr_reader :workspace

    # @param workspace [Solargraph::Workspace]
    def initialize workspace = Solargraph::Workspace.new(nil)
      @workspace = workspace
    end

    # @return [Solargraph::ApiMap]
    def api_map
      @api_map ||= Solargraph::ApiMap.new(workspace)
    end

    def open filename
      source = Solargraph::Source.load(filename)
      source_hash[filename] = source
      workspace.merge source
    end

    def create filename, text
      source = Solargraph::Source.load_string(text, filename)
      source_hash[filename] = source
      workspace.merge source
    end

    def close filename
    end

    # @return [Array<Solargraph::Pin::Base>]
    def completions_at filename, line, column
      source = read(filename)
      fragment = Solargraph::Source::Fragment.new(source, source.get_offset(line, column))
      type = api_map.infer_fragment_type(fragment)
      if fragment.signature.end_with?('.')
        api_map.get_methods_refactored(type)
      else
        raise 'HA! What now?'
      end
    end

    def definitions_at filename, line, column
      source = read(filename)
      fragment = Solargraph::Source::Fragment.new(source, source.get_offset(line, column))
      type = api_map.infer_fragment_type(fragment)
      api_map.get_path_suggestions(type)
    end

    def infer_type_at filename, line, column
      source = read(filename)
      fragment = Solargraph::Source::Fragment.new(source, source.get_offset(line, column))
      api_map.infer_fragment_type(fragment)    
    end

    def source filename
      source_hash[filename]
    end

    def self.load directory
      Solargraph::Library.new(Solargraph::Workspace.new(directory))
    end

    private

    # @return [Hash<String, Solargraph::Source>]
    def source_hash
      @source_hash ||= {}
    end

    def read filename
      source = source_hash[filename]
      raise FileNotFoundError, "Source not found for #{filename}" if source.nil?
      api_map.virtualize source
      source
    end
  end
end
