module Solargraph
  # A library handles coordination between a Workspace and an ApiMap.
  #
  class Library
    class FileNotFoundError < Exception; end

    # @param workspace [Solargraph::Workspace]
    def initialize workspace = Solargraph::Workspace.new(nil)
      @workspace = workspace
    end

    def open filename, text, version
      source = Solargraph::Source.load_string(text, filename)
      source.version = version
      source_hash[filename] = source
      workspace.merge source
      api_map.refresh
    end

    def create filename, text
      source = Solargraph::Source.load_string(text, filename)
      if workspace.merge(source)
        source_hash[filename] = source
        api_map.refresh
      end
    end

    def delete filename
      source = source_hash[filename]
      return if source.nil?
      source_hash.delete filename
      workspace.remove source
      api_map.refresh
    end

    def close filename
    end

    # Get completion suggestions at the specified file and location.
    #
    # @param filename [String] The file to analyze
    # @param line [Integer] The zero-based line number
    # @param column [Integer] The zero-based column number
    # @return [Array<Solargraph::Pin::Base>]
    def completions_at filename, line, column
      # @type [Solargraph::Source]
      source = read(filename)
      fragment = Solargraph::Source::Fragment.new(source, source.get_offset(line, column))
      api_map.complete(fragment)
    end

    def whole_word_range_at filename, line, column
      source = read(filename)
      fragment = Solargraph::Source::Fragment.new(source, source.get_offset(line, column))
      fragment.whole_word_range
    end

    # Get definition suggestions for the expression at the specified file and
    # location.
    #
    # @param filename [String] The file to analyze
    # @param line [Integer] The zero-based line number
    # @param column [Integer] The zero-based column number
    # @return [Array<Solargraph::Pin::Base>]
    def definitions_at filename, line, column
      source = read(filename)
      fragment = Solargraph::Source::Fragment.new(source, source.get_offset(line, column))
      result = api_map.define(fragment)
      result
    end

    # Get signature suggestions for the method at the specified file and
    # location.
    #
    # @param filename [String] The file to analyze
    # @param line [Integer] The zero-based line number
    # @param column [Integer] The zero-based column number
    # @return [Array<Solargraph::Pin::Base>]
    def signatures_at filename, line, column
      source = read(filename)
      fragment = Solargraph::Source::Fragment.new(source, signature_index_before(source, source.get_offset(line, column)))
      api_map.define(fragment).select{|pin| pin.method?}
    end

    # Get the pin at the specified location or nil if the pin does not exist.
    #
    # @return [Solargraph::Pin::Base]
    def locate_pin location
      api_map.locate_pin location
    end

    # Get an array of pins that match a path.
    #
    # @param path [String]
    # @return [Array<Solargraph::Pin::Base>]
    def get_path_pins path
      api_map.get_path_suggestions(path)
    end

    # Check a file out of the library. If the file is not part of the
    # workspace, the ApiMap will virtualize it for mapping purposes. If
    # filename is nil, any source currently checked out of the library
    # will be removed from the ApiMap. Only one file can be checked out
    # (virtualized) at a time.
    #
    # @raise [FileNotFoundError] if the file is not in the library.
    #
    # @param filename [String]
    # @return [Source]
    def checkout filename
      if filename.nil?
        api_map.virtualize nil
        nil
      else
        read filename
      end
    end

    def refresh force = false
      api_map.refresh force
    end

    def document query
      api_map.document query
    end

    def search query
      api_map.search query
    end

    def query_symbols query
      api_map.query_symbols query
    end

    def file_symbols filename
      read(filename).all_symbols
    end

    def path_pins path
      api_map.get_path_suggestions(path)
    end

    # Get the current text of a file in the library.
    #
    # @param filename [String]
    # @return [String]
    def read_code filename
      source = read(filename)
      source.code
    end

    # Create a library from a directory.
    #
    # @param directory [String] The path to be used for the workspace
    # @return [Solargraph::Library]
    def self.load directory
      Solargraph::Library.new(Solargraph::Workspace.new(directory))
    end

    private

    # @return [Hash<String, Solargraph::Source>]
    def source_hash
      @source_hash ||= {}
    end

    # @return [Solargraph::ApiMap]
    def api_map
      @api_map ||= Solargraph::ApiMap.new(workspace)
    end
    
    # @return [Solargraph::Workspace]
    def workspace
      @workspace
    end

    # @return [Solargraph::Source]
    def read filename
      source = source_hash[filename]
      raise FileNotFoundError, "Source not found for #{filename}" if source.nil?
      api_map.virtualize source
      source
    end

    def signature_index_before source, index
      open_parens = 0
      cursor = index - 1
      while cursor >= 0
        break if cursor < 0
        if source.code[cursor] == ')'
          open_parens -= 1
        elsif source.code[cursor] == '('
          open_parens += 1
        end
        break if open_parens == 1
        cursor -= 1
      end
      cursor = 0 if cursor < 0
      cursor
    end
  end
end
