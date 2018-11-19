module Solargraph
  # A Library handles coordination between a Workspace and an ApiMap.
  #
  class Library
    # @param workspace [Solargraph::Workspace]
    def initialize workspace = Solargraph::Workspace.new
      @mutex = Mutex.new
      @workspace = workspace
      api_map.catalog bundle
      @synchronized = true
    end

    # True if the ApiMap is up to date with the library's workspace and open
    # files.
    #
    # @return [Boolean]
    def synchronized?
      @synchronized
    end

    # Open a file in the library. Opening a file will make it available for
    # checkout and merge it into the workspace if applicable.
    #
    # @param filename [String]
    # @param text [String]
    # @param version [Integer]
    # @return [void]
    def open filename, text, version
      mutex.synchronize do
        source = Solargraph::Source.load_string(text, filename, version)
        workspace.merge source
        open_file_hash[filename] = source
        catalog #unless api_map.try_merge!(source)
      end
    end

    # True if the specified file is currently open.
    #
    # @param filename [String]
    # @return [Boolean]
    def open? filename
      open_file_hash.has_key? filename
    end

    # True if the specified file is included in the workspace (but not
    # necessarily open).
    #
    # @param filename [String]
    # @return [Boolean]
    def contain? filename
      workspace.has_file?(filename)
    end

    # Create a source to be added to the workspace. The file is ignored if the
    # workspace is not configured to include the file.
    #
    # @param filename [String]
    # @param text [String] The contents of the file
    # @return [Boolean] True if the file was added to the workspace.
    def create filename, text
      result = false
      mutex.synchronize do
        next unless workspace.would_merge?(filename)
        source = Solargraph::Source.load_string(text, filename)
        workspace.merge(source)
        catalog #unless api_map.try_merge!(source)
        result = true
      end
      result
    end

    # Create a file source from a file on disk. The file is ignored if the
    # workspace is not configured to include the file.
    #
    # @param filename [String]
    # @return [Boolean] True if the file was added to the workspace.
    def create_from_disk filename
      result = false
      mutex.synchronize do
        next if File.directory?(filename) or !File.exist?(filename)
        next unless workspace.would_merge?(filename)
        source = Solargraph::Source.load_string(File.read(filename), filename)
        workspace.merge(source)
        catalog #unless api_map.try_merge!(source)
        result = true
      end
      result
    end

    # Delete a file from the library. Deleting a file will make it unavailable
    # for checkout and optionally remove it from the workspace unless the
    # workspace configuration determines that it should still exist.
    #
    # @param filename [String]
    # @return [void]
    def delete filename
      mutex.synchronize do
        open_file_hash.delete filename
        workspace.remove filename
        catalog
      end
    end

    # Close a file in the library. Closing a file will make it unavailable for
    # checkout although it may still exist in the workspace.
    #
    # @param filename [String]
    # @return [void]
    def close filename
      mutex.synchronize do
        open_file_hash.delete filename
        catalog
      end
    end

    # Get completion suggestions at the specified file and location.
    #
    # @param filename [String] The file to analyze
    # @param line [Integer] The zero-based line number
    # @param column [Integer] The zero-based column number
    # @return [SourceMap::Completion]
    # @todo Take a Location instead of filename/line/column
    def completions_at filename, line, column
      position = Position.new(line, column)
      cursor = Source::Cursor.new(checkout(filename), position)
      api_map.clip(cursor).complete
    end

    # Get definition suggestions for the expression at the specified file and
    # location.
    #
    # @param filename [String] The file to analyze
    # @param line [Integer] The zero-based line number
    # @param column [Integer] The zero-based column number
    # @return [Array<Solargraph::Pin::Base>]
    # @todo Take filename/position instead of filename/line/column
    def definitions_at filename, line, column
      position = Position.new(line, column)
      cursor = Source::Cursor.new(checkout(filename), position)
      api_map.clip(cursor).define
    end

    # Get signature suggestions for the method at the specified file and
    # location.
    #
    # @param filename [String] The file to analyze
    # @param line [Integer] The zero-based line number
    # @param column [Integer] The zero-based column number
    # @return [Array<Solargraph::Pin::Base>]
    # @todo Take filename/position instead of filename/line/column
    def signatures_at filename, line, column
      position = Position.new(line, column)
      cursor = Source::Cursor.new(checkout(filename), position)
      api_map.clip(cursor).signify
    end

    # @param filename [String]
    # @param line [Integer]
    # @param column [Integer]
    # @param strip [Boolean] Strip special characters from variable names
    # @return [Array<Solargraph::Range>]
    # @todo Take a Location instead of filename/line/column
    def references_from filename, line, column, strip: false
      cursor = api_map.cursor_at(filename, Position.new(line, column))
      clip = api_map.clip(cursor)
      pins = clip.define
      return [] if pins.empty?
      result = []
      pins.uniq.each do |pin|
        (workspace.sources + open_file_hash.values).uniq.each do |source|
          found = source.references(pin.name)
          found.select! do |loc|
            referenced = definitions_at(loc.filename, loc.range.ending.line, loc.range.ending.character)
            referenced.any?{|r| r == pin}
          end
          # HACK for language clients that exclude special characters from the start of variable names
          if strip && match = cursor.word.match(/^[^a-z0-9_]+/i)
            found.map! do |loc|
              Solargraph::Location.new(loc.filename, Solargraph::Range.from_to(loc.range.start.line, loc.range.start.column + match[0].length, loc.range.ending.line, loc.range.ending.column))
            end
          end
          result.concat(found.sort{ |a, b|
            a.range.start.line <=> b.range.start.line
          })
        end
      end
      result
    end

    # Get the pin at the specified location or nil if the pin does not exist.
    #
    # @param location [Location]
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
    # @raise [FileNotFoundError] if the file does not exist.
    #
    # @param filename [String]
    # @return [Source]
    def checkout filename
      read filename
    end

    # @param query [String]
    # @return [Array<YARD::CodeObject::Base>]
    def document query
      api_map.document query
    end

    # @param query [String]
    # @return [Array<String>]
    def search query
      api_map.search query
    end

    # Get an array of all symbols in the workspace that match the query.
    #
    # @param query [String]
    # @return [Array<Pin::Base>]
    def query_symbols query
      api_map.query_symbols query
    end

    # Get an array of document symbols.
    #
    # Document symbols are composed of namespace, method, and constant pins.
    # The results of this query are appropriate for building the response to a
    # textDocument/documentSymbol message in the language server protocol.
    #
    # @param filename [String]
    # @return [Array<Solargraph::Pin::Base>]
    def document_symbols filename
      return [] unless open_file_hash.has_key?(filename)
      api_map.document_symbols(filename)
    end

    # @param path [String]
    # @return [Array<Solargraph::Pin::Base>]
    def path_pins path
      api_map.get_path_suggestions(path)
    end

    # Update a source in the library from the provided updater.
    #
    # @note This method will not update the library's ApiMap. See
    #   Library#ynchronized? and Library#catalog for more information.
    #
    #
    # @raise [FileNotFoundError] if the updater's file is not available.
    # @param updater [Solargraph::Source::Updater]
    # @return [void]
    def update updater
      mutex.synchronize do
        if workspace.has_file?(updater.filename)
          workspace.synchronize!(updater)
          open_file_hash[updater.filename] = workspace.source(updater.filename) if open?(updater.filename)
        else
          raise FileNotFoundError, "Unable to update #{updater.filename}" unless open?(updater.filename)
          open_file_hash[updater.filename] = open_file_hash[updater.filename].synchronize(updater)
        end
        @synchronized = false
      end
    end

    # Get the current text of a file in the library.
    #
    # @param filename [String]
    # @return [String]
    def read_text filename
      source = read(filename)
      source.code
    end

    # Get diagnostics about a file.
    #
    # @param filename [String]
    # @return [Array<Hash>]
    def diagnose filename
      # @todo Only open files get diagnosed. Determine whether anything or
      #   everything in the workspace should get diagnosed, or if there should
      #   be an option to do so.
      return [] unless open?(filename)
      result = []
      source = read(filename)
      workspace.config.reporters.each do |name|
        reporter = Diagnostics.reporter(name)
        raise DiagnosticsError, "Diagnostics reporter #{name} does not exist" if reporter.nil?
        result.concat reporter.new.diagnose(source, api_map)
      end
      result
    end

    # Update the ApiMap from the library's workspace and open files.
    #
    # @return [void]
    def catalog
      api_map.catalog bundle
      @synchronized = true
    end

    # Create a library from a directory.
    #
    # @param directory [String] The path to be used for the workspace
    # @return [Solargraph::Library]
    def self.load directory = ''
      Solargraph::Library.new(Solargraph::Workspace.new(directory))
    end

    private

    # @return [Mutex]
    attr_reader :mutex

    # @return [ApiMap]
    def api_map
      @api_map ||= Solargraph::ApiMap.new
    end

    # @return [YardMap]
    def yard_map
      @yard_map ||= Solargraph::YardMap.new
    end

    # @return [Bundle]
    def bundle
      Bundle.new(
        workspace: workspace,
        opened: open_file_hash.values
      )
    end

    # @return [Solargraph::Workspace]
    def workspace
      @workspace
    end

    # A collection of files that are currently open in the library. Open
    # files do not need to be in the workspace.
    #
    # @return [Hash{String => Source}]
    def open_file_hash
      @open_file_hash ||= {}
    end

    # Get the source for an open file or create a new source if the file
    # exists on disk. Sources created from disk are not added to the open
    # workspace files, i.e., the version on disk remains the authoritative
    # version.
    #
    # @raise [FileNotFoundError] if the file does not exist
    # @param filename [String]
    # @return [Solargraph::Source]
    def read filename
      return open_file_hash[filename] if open_file_hash.has_key?(filename)
      raise FileNotFoundError, "File not found: #{filename}" unless workspace.has_file?(filename)
      workspace.source(filename)
    end
  end
end
