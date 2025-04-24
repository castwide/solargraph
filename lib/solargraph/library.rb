# frozen_string_literal: true

require 'pathname'
require 'observer'

module Solargraph
  # A Library handles coordination between a Workspace and an ApiMap.
  #
  class Library
    include Logging
    include Observable

    # @return [Solargraph::Workspace]
    attr_reader :workspace

    # @return [String, nil]
    attr_reader :name

    # @return [Source, nil]
    attr_reader :current

    # @return [LanguageServer::Progress, nil]
    attr_reader :cache_progress

    # @param workspace [Solargraph::Workspace]
    # @param name [String, nil]
    def initialize workspace = Solargraph::Workspace.new, name = nil
      @workspace = workspace
      @name = name
      @threads = []
      # @type [Integer, nil]
      @total = nil
      # @type [Source, nil]
      @current = nil
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
      !mutex.locked?
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
      if @current && (!source || @current.filename != source.filename) && source_map_hash.key?(@current.filename) && !workspace.has_file?(@current.filename)
        source_map_hash.delete @current.filename
        source_map_external_require_hash.delete @current.filename
        @external_requires = nil
      end
      changed = source && @current != source
      @current = source
      maybe_map @current
      catalog if changed
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
      return false unless contain?(filename) || open?(filename)
      source = Solargraph::Source.load_string(text, filename)
      workspace.merge(source)
      true
    end

    # Create file sources from files on disk. A file is ignored if it is
    # neither open in the library nor included in the workspace.
    #
    # @param filenames [Array<String>]
    # @return [Boolean] True if at least one file was added to the workspace.
    def create_from_disk *filenames
      sources = filenames
        .reject { |filename| File.directory?(filename) || !File.exist?(filename) }
        .map { |filename| Solargraph::Source.load_string(File.read(filename), filename) }
      result = workspace.merge(*sources)
      sources.each { |source| maybe_map source }
      result
    end

    # Delete files from the library. Deleting a file will make it unavailable
    # for checkout and optionally remove it from the workspace unless the
    # workspace configuration determines that it should still exist.
    #
    # @param filenames [Array<String>]
    # @return [Boolean] True if any file was deleted
    def delete *filenames
      result = false
      filenames.each do |filename|
        detach filename
        result ||= workspace.remove(filename)
      end
      result
    end

    # Close a file in the library. Closing a file will make it unavailable for
    # checkout although it may still exist in the workspace.
    #
    # @param filename [String]
    # @return [void]
    def close filename
      return unless @current&.filename == filename

      @current = nil
      catalog unless workspace.has_file?(filename)
    end

    # Get completion suggestions at the specified file and location.
    #
    # @param filename [String] The file to analyze
    # @param line [Integer] The zero-based line number
    # @param column [Integer] The zero-based column number
    # @return [SourceMap::Completion, nil]
    # @todo Take a Location instead of filename/line/column
    def completions_at filename, line, column
      sync_catalog
      position = Position.new(line, column)
      cursor = Source::Cursor.new(read(filename), position)
      mutex.synchronize { api_map.clip(cursor).complete }
    rescue FileNotFoundError => e
      handle_file_not_found filename, e
    end

    # Get definition suggestions for the expression at the specified file and
    # location.
    #
    # @param filename [String] The file to analyze
    # @param line [Integer] The zero-based line number
    # @param column [Integer] The zero-based column number
    # @return [Array<Solargraph::Pin::Base>, nil]
    # @todo Take filename/position instead of filename/line/column
    def definitions_at filename, line, column
      position = Position.new(line, column)
      cursor = Source::Cursor.new(read(filename), position)
      sync_catalog
      if cursor.comment?
        source = read(filename)
        offset = Solargraph::Position.to_offset(source.code, Solargraph::Position.new(line, column))
        lft = source.code[0..offset-1].match(/\[[a-z0-9_:<, ]*?([a-z0-9_:]*)\z/i)
        rgt = source.code[offset..-1].match(/^([a-z0-9_]*)(:[a-z0-9_:]*)?[\]>, ]/i)
        if lft && rgt
          tag = (lft[1] + rgt[1]).sub(/:+$/, '')
          clip = mutex.synchronize { api_map.clip(cursor) }
          clip.translate tag
        else
          []
        end
      else
        mutex.synchronize { api_map.clip(cursor).define.map { |pin| pin.realize(api_map) } }
      end
    rescue FileNotFoundError => e
      handle_file_not_found(filename, e)
    end

    # Get type definition suggestions for the expression at the specified file and
    # location.
    #
    # @param filename [String] The file to analyze
    # @param line [Integer] The zero-based line number
    # @param column [Integer] The zero-based column number
    # @return [Array<Solargraph::Pin::Base>, nil]
    # @todo Take filename/position instead of filename/line/column
    def type_definitions_at filename, line, column
      position = Position.new(line, column)
      cursor = Source::Cursor.new(read(filename), position)
      sync_catalog
      mutex.synchronize { api_map.clip(cursor).types }
    rescue FileNotFoundError => e
      handle_file_not_found filename, e
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
      sync_catalog
      mutex.synchronize { api_map.clip(cursor).signify }
    end

    # @param filename [String]
    # @param line [Integer]
    # @param column [Integer]
    # @param strip [Boolean] Strip special characters from variable names
    # @param only [Boolean] Search for references in the current file only
    # @return [Array<Solargraph::Location>]
    # @todo Take a Location instead of filename/line/column
    def references_from filename, line, column, strip: false, only: false
      sync_catalog
      cursor = Source::Cursor.new(read(filename), [line, column])
      clip = mutex.synchronize { api_map.clip(cursor) }
      pin = clip.define.first
      return [] unless pin
      result = []
      files = if only
        [api_map.source_map(filename)]
      else
        (workspace.sources + (@current ? [@current] : []))
      end
      files.uniq(&:filename).each do |source|
        found = source.references(pin.name)
        found.select! do |loc|
          referenced = definitions_at(loc.filename, loc.range.ending.line, loc.range.ending.character).first
          referenced&.path == pin.path
        end
        if pin.path == 'Class#new'
          caller = cursor.chain.base.infer(api_map, clip.send(:block), clip.locals).first
          if caller.defined?
            found.select! do |loc|
              clip = api_map.clip_at(loc.filename, loc.range.start)
              other = clip.send(:cursor).chain.base.infer(api_map, clip.send(:block), clip.locals).first
              caller == other
            end
          else
            found.clear
          end
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
      result.uniq
    end

    # Get the pins at the specified location or nil if the pin does not exist.
    #
    # @param location [Location]
    # @return [Array<Solargraph::Pin::Base>]
    def locate_pins location
      sync_catalog
      mutex.synchronize { api_map.locate_pins(location).map { |pin| pin.realize(api_map) } }
    end

    # Match a require reference to a file.
    #
    # @param location [Location]
    # @return [Location, nil]
    def locate_ref location
      map = source_map_hash[location.filename]
      return if map.nil?
      pin = map.requires.select { |p| p.location.range.contain?(location.range.start) }.first
      return nil if pin.nil?
      # @param full [String]
      return_if_match = proc do |full|
        if source_map_hash.key?(full)
          return Location.new(full, Solargraph::Range.from_to(0, 0, 0, 0))
        end
      end
      workspace.require_paths.each do |path|
        full = File.join path, pin.name
        return_if_match.(full)
        return_if_match.(full << ".rb")
      end
      nil
    rescue FileNotFoundError
      nil
    end

    # Get an array of pins that match a path.
    #
    # @param path [String]
    # @return [Enumerable<Solargraph::Pin::Base>]
    def get_path_pins path
      sync_catalog
      mutex.synchronize { api_map.get_path_suggestions(path) }
    end

    # @param query [String]
    # @return [Enumerable<YARD::CodeObjects::Base>]
    def document query
      sync_catalog
      mutex.synchronize { api_map.document query }
    end

    # @param query [String]
    # @return [Array<String>]
    def search query
      sync_catalog
      mutex.synchronize { api_map.search query }
    end

    # Get an array of all symbols in the workspace that match the query.
    #
    # @param query [String]
    # @return [Array<Pin::Base>]
    def query_symbols query
      sync_catalog
      mutex.synchronize { api_map.query_symbols query }
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
      sync_catalog
      mutex.synchronize { api_map.document_symbols(filename) }
    end

    # @param path [String]
    # @return [Enumerable<Solargraph::Pin::Base>]
    def path_pins path
      sync_catalog
      mutex.synchronize { api_map.get_path_suggestions(path) }
    end

    # @return [Array<SourceMap>]
    def source_maps
      source_map_hash.values
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
      sync_catalog
      return [] unless open?(filename)
      result = []
      source = read(filename)

      # @type [Hash{Class<Solargraph::Diagnostics::Base> => Array<String>}]
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
      @threads.delete_if(&:stop?)
      @threads.push(Thread.new do
        sleep 0.05 if RUBY_PLATFORM =~ /mingw/
        next unless @threads.last == Thread.current

        mutex.synchronize do
          logger.info "Cataloging #{workspace.directory.empty? ? 'generic workspace' : workspace.directory}"
          api_map.catalog bench
          logger.info "Catalog complete (#{api_map.source_maps.length} files, #{api_map.pins.length} pins)"
          logger.info "#{api_map.uncached_gemspecs.length} uncached gemspecs"
          cache_next_gemspec
        end
      end)
      @threads.last.run if RUBY_PLATFORM =~ /mingw/
    end

    # @return [Bench]
    def bench
      Bench.new(
        source_maps: source_map_hash.values,
        workspace: workspace,
        external_requires: external_requires
      )
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
      Logging.logger.debug "Merging source: #{source.filename}"
      result = workspace.merge(source)
      maybe_map source
      result
    end

    # @return [Hash{String => SourceMap}]
    def source_map_hash
      @source_map_hash ||= {}
    end

    def mapped?
      (workspace.filenames - source_map_hash.keys).empty?
    end

    # @return [SourceMap, Boolean]
    def next_map
      return false if mapped?
      src = workspace.sources.find { |s| !source_map_hash.key?(s.filename) }
      if src
        Logging.logger.debug "Mapping #{src.filename}"
        source_map_hash[src.filename] = Solargraph::SourceMap.map(src)
        find_external_requires(source_map_hash[src.filename])
        source_map_hash[src.filename]
      else
        false
      end
    end

    # @return [self]
    def map!
      workspace.sources.each do |src|
        source_map_hash[src.filename] = Solargraph::SourceMap.map(src)
        find_external_requires(source_map_hash[src.filename])
      end
      self
    end

    # @return [Array<Solargraph::Pin::Base>]
    def pins
      @pins ||= []
    end

    # @return [Set<String>]
    def external_requires
      @external_requires ||= source_map_external_require_hash.values.flatten.to_set
    end

    private

    # @return [Hash{String => Set<String>}]
    def source_map_external_require_hash
      @source_map_external_require_hash ||= {}
    end

    # @param source_map [SourceMap]
    # @return [void]
    def find_external_requires source_map
      new_set = source_map.requires.map(&:name).to_set
      # return if new_set == source_map_external_require_hash[source_map.filename]
      _filenames = nil
      filenames = ->{ _filenames ||= workspace.filenames.to_set }
      source_map_external_require_hash[source_map.filename] = new_set.reject do |path|
        workspace.require_paths.any? do |base|
          full = File.join(base, path)
          filenames[].include?(full) or filenames[].include?(full << ".rb")
        end
      end
      @external_requires = nil
    end

    # @return [Mutex]
    def mutex
      @mutex ||= Mutex.new
    end

    # @return [ApiMap]
    def api_map
      @api_map ||= Solargraph::ApiMap.new
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

    # @param filename [String]
    # @param error [FileNotFoundError]
    # @return [nil]
    def handle_file_not_found filename, error
      if workspace.source(filename)
        Solargraph.logger.debug "#{filename} is not cataloged in the ApiMap"
        nil
      else
        raise error
      end
    end

    # @param source [Source, nil]
    # @return [void]
    def maybe_map source
      return unless source
      return unless @current == source || workspace.has_file?(source.filename)
      if source_map_hash.key?(source.filename)
        return if source_map_hash[source.filename].code == source.code &&
          source_map_hash[source.filename].source.synchronized? &&
          source.synchronized?
        if source.synchronized?
          new_map = Solargraph::SourceMap.map(source)
          unless source_map_hash[source.filename].try_merge!(new_map)
            source_map_hash[source.filename] = new_map
            find_external_requires(source_map_hash[source.filename])
          end
        else
          # @todo Smelly instance variable access
          source_map_hash[source.filename].instance_variable_set(:@source, source)
        end
      else
        source_map_hash[source.filename] = Solargraph::SourceMap.map(source)
        find_external_requires(source_map_hash[source.filename])
      end
    end

    # @return [Set<Gem::Specification>]
    def cache_errors
      @cache_errors ||= Set.new
    end

    # @return [void]
    def cache_next_gemspec
      return if @cache_progress
      spec = api_map.uncached_gemspecs.find { |spec| !cache_errors.include?(spec) }
      return end_cache_progress unless spec

      pending = api_map.uncached_gemspecs.length - cache_errors.length - 1
      logger.info "Caching #{spec.name} #{spec.version}"
      Thread.new do
        cache_pid = Process.spawn(workspace.command_path, 'cache', spec.name, spec.version.to_s)
        report_cache_progress spec.name, pending
        Process.wait(cache_pid)
        logger.info "Cached #{spec.name} #{spec.version}"
      rescue Errno::EINVAL => _e
        logger.info "Cached #{spec.name} #{spec.version} with EINVAL"
      rescue StandardError => e
        cache_errors.add spec
        Solargraph.logger.warn "Error caching gemspec #{spec.name} #{spec.version}: [#{e.class}] #{e.message}"
      ensure
        end_cache_progress
        catalog
      end
    end

    # @param gem_name [String]
    # @param pending [Integer]
    # @return [void]
    def report_cache_progress gem_name, pending
      @total ||= pending
      @total = pending if pending > @total
      finished = @total - pending
      pct = if @total.zero?
        0
      else
        ((finished.to_f / @total.to_f) * 100).to_i
      end
      message = "#{gem_name}#{pending > 0 ? " (+#{pending})" : ''}"
      # "
      if @cache_progress
        @cache_progress.report(message, pct)
      else
        @cache_progress = LanguageServer::Progress.new('Caching gem')
        # If we don't send both a begin and a report, the progress notification
        # might get stuck in the status bar forever
        @cache_progress.begin(message, pct)
        changed
        notify_observers @cache_progress
        @cache_progress.report(message, pct)
      end
      changed
      notify_observers @cache_progress
    end

    # @return [void]
    def end_cache_progress
      changed if @cache_progress&.finish('done')
      notify_observers @cache_progress
      @cache_progress = nil
      @total = nil
    end

    def sync_catalog
      @threads.delete_if(&:stop?)
              .last&.join
    end
  end
end
