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
      source = Solargraph::Source.load_string(text.gsub(/\r\n/, "\n"), filename)
      source.version = version
      source_hash[filename] = source
      workspace.merge source
      api_map.refresh
    end

    def create filename, text
      source = Solargraph::Source.load_string(text.gsub(/\r\n/, "\n"), filename)
      source_hash[filename] = source
      workspace.merge source
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
      result = []
      if fragment.signature.include?('.')
        type = api_map.infer_fragment_type(fragment)
        result.concat api_map.get_type_methods(type, fragment.namespace) unless type.nil?
      else
        if fragment.signature.start_with?('@@')
          result.concat api_map.get_class_variable_pins(fragment.namespace)
        elsif fragment.signature.start_with?('@')
          result.concat api_map.get_instance_variables(fragment.namespace, fragment.scope)
        elsif fragment.signature.start_with?('$')
          result.concat api_map.get_global_variable_pins
        elsif fragment.signature.start_with?(':') and !fragment.signature.start_with?('::')
          result.concat api_map.get_symbols
        else
          unless fragment.signature.include?('::')
            result.concat source.local_variable_pins.select{|pin| pin.visible_from?(fragment.node)}
            result.concat api_map.get_type_methods(fragment.namespace, fragment.namespace)
            result.concat api_map.get_type_methods('Kernel')
          end
          result.concat api_map.get_constants(fragment.base, fragment.namespace)
        end
      end
      result.uniq(&:path).select{|s| s.kind != Solargraph::LanguageServer::CompletionItemKinds::METHOD or s.name.match(/^[a-z0-9_]*(\!|\?|=)?$/i)}.sort_by.with_index{ |x, idx| [x.name, idx] }
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
      type = api_map.infer_fragment_path(fragment)
      api_map.get_path_suggestions(type)
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
      type = api_map.infer_fragment_path(fragment)
      api_map.get_path_suggestions(type)
    end

    def tmp_api_map
      api_map
    end

    # Get the range (start and end locations) for the symbol at the specified
    # file and location. A symbol range encompasses the complete word,
    # including trailing characters.
    #
    # @param filename [String] The file to analyze
    # @param line [Integer] The zero-based line number
    # @param column [Integer] The zero-based column number
    # @return [Hash]
    def symbol_range_at filename, line, column
      source = read(filename)
      index = source.get_offset(line, column)
      cursor = index
      while cursor > -1
        char = source.code[cursor - 1, 1]
        break if char.nil? or char == ''
        break unless char.match(/[a-z0-9_@$]/i)
        cursor -= 1
      end
      start_offset = cursor
      start_offset -= 1 if (start_offset > 1 and source.code[start_offset - 1] == ':') and (start_offset == 1 or source.code[start_offset - 2] != ':')
      cursor = index
      while cursor < source.code.length
        char = source.code[cursor, 1]
        break if char.nil? or char == ''
        break unless char.match(/[a-z0-9_\?\!]/i)
        cursor += 1
      end
      end_offset = cursor
      end_offset = start_offset if end_offset < start_offset
      start_pos = Solargraph::Source.get_position_at(source.code, start_offset)
      end_pos = Solargraph::Source.get_position_at(source.code, end_offset)
      result = {
        start: {
          line: start_pos[0],
          character: start_pos[1]
        },
        end: {
          line: end_pos[0],
          character: end_pos[1]
        }
      }
      result
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

    # Get the type for the signature at the specified location.
    #
    # @return [String]
    def infer_type_at filename, line, column
      source = read(filename)
      fragment = Solargraph::Source::Fragment.new(source, source.get_offset(line, column))
      api_map.infer_fragment_type(fragment)    
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
