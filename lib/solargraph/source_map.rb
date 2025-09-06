# frozen_string_literal: true

require 'yard'
require 'solargraph/yard_tags'

module Solargraph
  # An index of Pins and other ApiMap-related data for a single Source
  # that can be queried.
  #
  class SourceMap
    autoload :Mapper,        'solargraph/source_map/mapper'
    autoload :Clip,          'solargraph/source_map/clip'
    autoload :Completion,    'solargraph/source_map/completion'
    autoload :Data,          'solargraph/source_map/data'

    # @return [Source]
    attr_reader :source

    # @return [Array<Pin::Base>]
    def pins
      data.pins
    end

    # @return [Array<Pin::Base>]
    def all_pins
      pins + convention_pins
    end

    # @return [Array<Pin::LocalVariable>]
    def locals
      data.locals
    end

    # @param source [Source]
    def initialize source
      @source = source

      conventions_environ.merge Convention.for_local(self) unless filename.nil?
      # FIXME: unmemoizing the document_symbols in case it was called and memoized from any of conventions above
      # this is to ensure that the convention_pins from all conventions are used in the document_symbols.
      # solargraph-rails is known to use this method to get the document symbols. It should probably be removed.
      @document_symbols = nil
      self.convention_pins = conventions_environ.pins
      @pin_select_cache = {}
    end

    # @generic T
    # @param klass [Class<generic<T>>]
    # @return [Array<generic<T>>]
    def pins_by_class klass
      @pin_select_cache[klass] ||= pin_class_hash.select { |key, _| key <= klass }.values.flatten
    end

    # A hash representing the state of the source map's API.
    #
    # ApiMap#catalog uses this value to determine whether it needs to clear its
    # cache.
    #
    # @return [Integer]
    def api_hash
      @api_hash ||= (pins_by_class(Pin::Constant) + pins_by_class(Pin::Namespace).select { |pin| pin.namespace.to_s > '' } + pins_by_class(Pin::Reference) + pins_by_class(Pin::Method).map(&:node) + locals).hash
    end

    # @return [String]
    def filename
      source.filename
    end

    # @return [String]
    def code
      source.code
    end

    # @return [Array<Pin::Reference::Require>]
    def requires
      pins_by_class(Pin::Reference::Require)
    end

    # @return [Environ]
    def conventions_environ
      @conventions_environ ||= Environ.new
    end

    # all pins except Solargraph::Pin::Reference::Reference
    # @return [Array<Pin::Base>]
    def document_symbols
      @document_symbols ||= (pins + convention_pins).select do |pin|
        pin.path && !pin.path.empty?
      end
    end

    # @param query [String]
    # @return [Array<Pin::Base>]
    def query_symbols query
      Pin::Search.new(document_symbols, query).results
    end

    # @param position [Position]
    # @return [Source::Cursor]
    def cursor_at position
      Source::Cursor.new(source, position)
    end

    # @param path [String]
    # @return [Pin::Base]
    def first_pin path
      pins.select { |p| p.path == path }.first
    end

    # @param location [Solargraph::Location]
    # @return [Array<Solargraph::Pin::Base>]
    def locate_pins location
      # return nil unless location.start_with?("#{filename}:")
      (pins + locals).select { |pin| pin.location == location }
    end

    # @param line [Integer]
    # @param character [Integer]
    # @return [Pin::Method,Pin::Namespace]
    def locate_named_path_pin line, character
      _locate_pin line, character, Pin::Namespace, Pin::Method
    end

    # @param line [Integer]
    # @param character [Integer]
    # @return [Pin::Namespace,Pin::Method,Pin::Block]
    def locate_block_pin line, character
      _locate_pin line, character, Pin::Namespace, Pin::Method, Pin::Block
    end

    # @param name [String]
    # @return [Array<Location>]
    def references name
      source.references name
    end

    # @param location [Location]
    # @return [Array<Pin::LocalVariable>]
    def locals_at(location)
      return [] if location.filename != filename
      closure = locate_named_path_pin(location.range.start.line, location.range.start.character)
      locals.select { |pin| pin.visible_at?(closure, location) }
    end

    class << self
      # @param filename [String]
      # @return [SourceMap]
      def load filename
        source = Solargraph::Source.load(filename)
        SourceMap.map(source)
      end

      # @param code [String]
      # @param filename [String, nil]
      # @return [SourceMap]
      def load_string code, filename = nil
        source = Solargraph::Source.load_string(code, filename)
        SourceMap.map(source)
      end

      # @deprecated
      # @param source [Source]
      # @return [SourceMap]
      def map source
        new(source)
      end
    end

    private

    # @return [Hash{Class => Array<Pin::Base>}]
    # @return [Array<Pin::Base>]
    attr_writer :convention_pins

    def pin_class_hash
      @pin_class_hash ||= pins.to_set.classify(&:class).transform_values(&:to_a)
    end

    # @return [Data]
    def data
      @data ||= Data.new(source)
    end

    # @return [Array<Pin::Base>]
    def convention_pins
      @convention_pins || []
    end

    # @param line [Integer]
    # @param character [Integer]
    # @param klasses [Array<Class>]
    # @return [Pin::Base, nil]
    def _locate_pin line, character, *klasses
      position = Position.new(line, character)
      found = nil
      pins.each do |pin|
        # @todo Attribute pins should not be treated like closures, but
        #   there's probably a better way to handle it
        next if pin.is_a?(Pin::Method) && pin.attribute?
        found = pin if (klasses.empty? || klasses.any? { |kls| pin.is_a?(kls) } ) && pin.location.range.contain?(position)
        break if pin.location.range.start.line > line
      end
      # Assuming the root pin is always valid
      found || pins.first
    end
  end
end
