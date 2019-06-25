# frozen_string_literal: true

module Solargraph
  # A Library handles coordination between a Workspace and an ApiMap.
  #
  class Library
    include Logging

    # @return [Solargraph::Workspace]
    attr_reader :workspace

    # @return [String, nil]
    attr_reader :name

    # @return [Source, nil]
    attr_reader :current

    # @param workspace [Solargraph::Workspace]
    # @param name [String, nil]
    def initialize workspace = Solargraph::Workspace.new, name = nil
      @workspace = workspace
      @name = name
      api_map.catalog bundle
      @synchronized = true
      @catalog_mutex = Mutex.new
    end

    def inspect
      # Let's not deal with insane data dumps in spec failures
      to_s
    end

    # True if the ApiMap is up to date with the library's workspace and open
    # files.
    #
    # @return [Boolean]
    def synchronized?
      @synchronized
    end

    # Attach a source to the library.
    #
    # The attached source does not need to be a part of the workspace. The
    # library will include it in the ApiMap while it's attached. Only one
    # source can be attached to the library at a time.
    #
    # @param source [Source, nil]
    # @return [void]
    def attach source
      mutex.synchronize do
        @synchronized = (@current == source) if synchronized?
        @current = source
        catalog
      end
    end

    # True if the specified file is currently attached.
    #
    # @param filename [String]
    # @return [Boolean]
    def attached? filename
      !@current.nil? && @current.filename == filename
    end
    alias open? attached?

    # Detach the specified file if it is currently attached to the library.
    #
    # @param filename [String]
    # @return [Boolean] True if the specified file was detached
    def detach filename
      return false if @current.nil? || @current.filename != filename
      attach nil
      true
    end

    # True if the specified file is included in the workspace (but not
    # necessarily open).
    #
    # @param filename [String]
    # @return [Boolean]
    def contain? filename
      workspace.has_file?(filename)
    end

    # Create a source to be added to the workspace. The file is ignored if it is
    # neither open in the library nor included in the workspace.
    #
    # @param filename [String]
    # @param text [String] The contents of the file
    # @return [Boolean] True if the file was added to the workspace.
    def create filename, text
      result = false
      mutex.synchronize do
        next unless contain?(filename) || open?(filename) || workspace.would_merge?(filename)
        @synchronized = false
        source = Solargraph::Source.load_string(text, filename)
        workspace.merge(source)
        result = true
      end
      result
    end

    # Create a file source from a file on disk. The file is ignored if it is
    # neither open in the library nor included in the workspace.
    #
    # @param filename [String]
    # @return [Boolean] True if the file was added to the workspace.
    def create_from_disk filename
      result = false
      mutex.synchronize do
        next if File.directory?(filename) || !File.exist?(filename)
        next unless contain?(filename) || open?(filename) || workspace.would_merge?(filename)
        @synchronized = false
        source = Solargraph::Source.load_string(File.read(filename), filename)
        workspace.merge(source)
        result = true
      end
      result
    end

    # Delete a file from the library. Deleting a file will make it unavailable
    # for checkout and optionally remove it from the workspace unless the
    # workspace configuration determines that it should still exist.
    #
    # @param filename [String]
    # @return [Boolean] True if the file was deleted
    def delete filename
      detach filename
      result = false
      mutex.synchronize do
        result = workspace.remove(filename)
        @synchronized = !result if synchronized?
      end
      result
    end

    # Close a file in the library. Closing a file will make it unavailable for
    # checkout although it may still exist in the workspace.
    #
    # @param filename [String]
    # @return [void]
    def close filename
      mutex.synchronize do
        @synchronized = false
        @current = nil if @current && @current.filename == filename
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
      cursor = Source::Cursor.new(read(filename), position)
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
      cursor = Source::Cursor.new(read(filename), position)
      api_map.clip(cursor).define.map { |pin| pin.realize(api_map) }
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
      cursor = Source::Cursor.new(read(filename), position)
      api_map.clip(cursor).signify
    end

    # @param filename [String]
    # @param line [Integer]
    # @param column [Integer]
    # @param strip [Boolean] Strip special characters from variable names
    # @return [Array<Solargraph::Range>]
    # @todo Take a Location instead of filename/line/column
    def references_from filename, line, column, strip: false
      # checkout filename
      cursor = api_map.cursor_at(filename, Position.new(line, column))
      clip = api_map.clip(cursor)
      pins = clip.define
      return [] if pins.empty?
      result = []
      pins.uniq.each do |pin|
        (workspace.sources + (@current ? [@current] : [])).uniq(&:filename).each do |source|
          found = source.references(pin.name)
          found.select! do |loc|
            referenced = definitions_at(loc.filename, loc.range.ending.line, loc.range.ending.character)
            # HACK: The additional location comparison is necessary because
            # Clip#define can return proxies for parameter pins
            referenced.any?{|r| r == pin || r.location == pin.location}
          end
          # HACK: for language clients that exclude special characters from the start of variable names
          if strip && match = cursor.word.match(/^[^a-z0-9_]+/i)
            found.map! do |loc|
              Solargraph::Location.new(loc.filename, Solargraph::Range.from_to(loc.range.start.line, loc.range.start.column + match[0].length, loc.range.ending.line, loc.range.ending.column))
            end
          end
          result.concat(found.sort do |a, b|
            a.range.start.line <=> b.range.start.line
          end)
        end
      end
      result.uniq
    end

    # Get the pin at the specified location or nil if the pin does not exist.
    #
    # @param location [Location]
    # @return [Solargraph::Pin::Base]
    def locate_pins location
      api_map.locate_pins(location).map { |pin| pin.realize(api_map) }
    end

    def locate_ref location
      api_map.require_reference_at location
    end

    # Get an array of pins that match a path.
    #
    # @param path [String]
    # @return [Array<Solargraph::Pin::Base>]
    def get_path_pins path
      api_map.get_path_suggestions(path)
    end

    # @param query [String]
    # @return [Array<YARD::CodeObject::Base>]
    def document query
      catalog
      api_map.document query
    end

    # @param query [String]
    # @return [Array<String>]
    def search query
      catalog
      api_map.search query
    end

    # Get an array of all symbols in the workspace that match the query.
    #
    # @param query [String]
    # @return [Array<Pin::Base>]
    def query_symbols query
      catalog
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
      # checkout filename
      api_map.document_symbols(filename)
    end

    # @param path [String]
    # @return [Array<Solargraph::Pin::Base>]
    def path_pins path
      catalog
      api_map.get_path_suggestions(path)
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
      #
      return [] unless open?(filename)
      catalog
      result = []
      source = read(filename)
      repargs = {}
      workspace.config.reporters.each do |line|
        if line == 'all!'
          Diagnostics.reporters.each do |reporter|
            repargs[reporter] ||= []
          end
        else
          args = line.split(':').map(&:strip)
          name = args.shift
            reporter = Diagnostics.reporter(name)
          raise DiagnosticsError, "Diagnostics reporter #{name} does not exist" if reporter.nil?
          repargs[reporter] ||= []
          repargs[reporter].concat args
        end
      end
      repargs.each_pair do |reporter, args|
        result.concat reporter.new(*args.uniq).diagnose(source, api_map)
      end
      result
    end

    # Update the ApiMap from the library's workspace and open files.
    #
    # @return [void]
    def catalog
      @catalog_mutex.synchronize do
        break if synchronized?
        logger.info "Cataloging #{workspace.directory.empty? ? 'generic workspace' : workspace.directory}"
        api_map.catalog bundle
        @synchronized = true
        logger.info "Catalog complete (#{api_map.pins.length} pins)"
      end
    end

    # Get an array of foldable ranges for the specified file.
    #
    # @deprecated The library should not need to handle folding ranges. The
    #   source itself has all the information it needs.
    #
    # @param filename [String]
    # @return [Array<Range>]
    def folding_ranges filename
      read(filename).folding_ranges
    end

    # Create a library from a directory.
    #
    # @param directory [String] The path to be used for the workspace
    # @param name [String, nil]
    # @return [Solargraph::Library]
    def self.load directory = '', name = nil
      Solargraph::Library.new(Solargraph::Workspace.new(directory), name)
    end

    # Try to merge a source into the library's workspace. If the workspace is
    # not configured to include the source, it gets ignored.
    #
    # @param source [Source]
    # @return [Boolean] True if the source was merged into the workspace.
    def merge source
      result = nil
      mutex.synchronize do
        result = workspace.merge(source)
        @synchronized = !result if synchronized?
      end
      result
    end

    private

    # @return [Mutex]
    def mutex
      @mutex ||= Mutex.new
    end

    # @return [ApiMap]
    def api_map
      @api_map ||= Solargraph::ApiMap.new
    end

    # @return [Bundle]
    def bundle
      Bundle.new(
        workspace: workspace,
        opened: @current ? [@current] : []
      )
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
      return @current if @current && @current.filename == filename
      raise FileNotFoundError, "File not found: #{filename}" unless workspace.has_file?(filename)
      workspace.source(filename)
    end
  end
end
