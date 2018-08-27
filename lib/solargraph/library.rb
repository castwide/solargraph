module Solargraph
  # A library handles coordination between a Workspace and an ApiMap.
  #
  class Library
    # @param workspace [Solargraph::Workspace]
    def initialize workspace = Solargraph::Workspace.new(nil)
      @workspace = workspace
      api_map
    end

    # Open a file in the library. Opening a file will make it available for
    # checkout and merge it into the workspace if applicable.
    #
    # @param filename [String]
    # @param text [String]
    # @param version [Integer]
    def open filename, text, version
      source = Solargraph::Source.load_string(text, filename)
      source.version = version
      source_hash[filename] = source
      workspace.merge source
      api_map.refresh
    end

    # True if the specified file is currently open in the workspace.
    #
    # @param filename [String]
    # @return [Boolean]
    def open? filename
      source_hash.has_key? filename
    end

    # True if the specified file is included in the workspace (but not
    # necessarily open).
    #
    # @param filename [String]
    # @return [Boolean]
    def contain? filename
      workspace.has_file?(filename)
    end

    # Create a file source to be added to the workspace. The file is ignored
    # if the workspace is not configured to include the file.
    #
    # @param filename [String]
    # @param text [String] The contents of the file
    # @return [Boolean] True if the file was added to the workspace.
    def create filename, text
      return false unless workspace.would_merge?(filename)
      source = Solargraph::Source.load_string(text, filename)
      workspace.merge(source)
      api_map.refresh
      true
    end

    # Create a file source from a file on disk. The file is ignored if the
    # workspace is not configured to include the file.
    #
    # @param filename [String]
    # @return [Boolean] True if the file was added to the workspace.
    def create_from_disk filename
      return false if File.directory?(filename) or !File.exist?(filename)
      return false unless workspace.would_merge?(filename)
      source = Solargraph::Source.load_string(File.read(filename), filename)
      workspace.merge(source)
      api_map.refresh
      true
    end

    # Delete a file from the library. Deleting a file will make it unavailable
    # for checkout and optionally remove it from the workspace unless the
    # workspace configuration determines that it should still exist.
    #
    # @param filename [String]
    def delete filename
      source = source_hash[filename]
      return if source.nil?
      source_hash.delete filename
      workspace.remove source
      api_map.refresh
    end

    # Close a file in the library. Closing a file will make it unavailable for
    # checkout although it may still exist in the workspace.
    #
    # @param filename [String]
    def close filename
      source_hash.delete filename
      if workspace.has_file?(filename)
        source = Solargraph::Source.load(filename)
        workspace.merge source
      end
    end

    # @param filename [String]
    # @param version [Integer]
    def overwrite filename, version
      source = source_hash[filename]
      return if source.nil?
      if source.version > version
        STDERR.puts "Save out of sync for #{filename} (current #{source.version}, overwrite #{version})" if source.version > version
      else
        open filename, File.read(filename), version
      end
    end

    # Get completion suggestions at the specified file and location.
    #
    # @param filename [String] The file to analyze
    # @param line [Integer] The zero-based line number
    # @param column [Integer] The zero-based column number
    # @return [ApiMap::Completion]
    def completions_at filename, line, column
      source = read(filename)
      api_map.virtualize source
      fragment = source.fragment_at(line, column)
      api_map.complete(fragment)
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
      api_map.virtualize source
      fragment = source.fragment_at(line, column)
      api_map.define(fragment)
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
      api_map.virtualize source
      fragment = source.fragment_at(line, column)
      api_map.signify(fragment)
    end

    # @param filename [String]
    # @param line [Integer]
    # @param column [Integer]
    # @return [Array<Solargraph::Source::Range>]
    def references_from filename, line, column
      source = read(filename)
      api_map.virtualize source
      fragment = source.fragment_at(line, column)
      pins = api_map.define(fragment)
      return [] if pins.empty?
      result = []
      # @param pin [Solargraph::Pin::Base]
      pins.uniq.each do |pin|
        if pin.kind != Solargraph::Pin::NAMESPACE and !pin.location.nil?
          mn_loc = get_symbol_name_location(pin)
          result.push mn_loc unless mn_loc.nil?
        end
        (workspace.sources + source_hash.values).uniq(&:filename).each do |source|
          found = source.references(pin.name)
          found.select do |loc|
            referenced = definitions_at(loc.filename, loc.range.ending.line, loc.range.ending.character)
            referenced.any?{|r| r.path == pin.path}
          end
          result.concat found.sort{|a, b| a.range.start.line <=> b.range.start.line}
        end
      end
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

    # @param filename [String]
    # @return [Array<Solargraph::Pin::Base>]
    def file_symbols filename
      read(filename).all_symbols
    end

    # @param path [String]
    # @return [Array<Solargraph::Pin::Base>]
    def path_pins path
      api_map.get_path_suggestions(path)
    end

    # @param updater [Solargraph::Source::Updater]
    def synchronize updater, reparse = true
      source = read(updater.filename)
      source.synchronize updater, reparse
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

    # Get the source for an open file or create a new source if the file
    # exists on disk. Sources created from disk are not added to the open
    # workspace files, i.e., the version on disk remains the authoritative
    # version.
    #
    # @raise [FileNotFoundError] if the file does not exist
    # @param filename [String]
    # @return [Solargraph::Source]
    def read filename
      return source_hash[filename] if open?(filename)
      return workspace.source(filename) if workspace.has_file?(filename)
      raise FileNotFoundError, "File not found: #{filename}" unless File.file?(filename)
      Solargraph::Source.load(filename)
    end

    def get_symbol_name_location pin
      decsrc = read(pin.location.filename)
      offset = Solargraph::Source::Position.to_offset(decsrc.code, pin.location.range.start)
      soff = decsrc.code.index(pin.name, offset)
      eoff = soff + pin.name.length
      Solargraph::Source::Location.new(
        pin.location.filename, Solargraph::Source::Range.new(
          Solargraph::Source::Position.from_offset(decsrc.code, soff),
          Solargraph::Source::Position.from_offset(decsrc.code, eoff)
        )
      )
    end
  end
end
