require 'jaro_winkler'

module Solargraph
  # An index of pins and other ApiMap-related data for a Source.
  #
  class SourceMap
    autoload :NodeProcessor, 'solargraph/source_map/node_processor'
    autoload :Mapper,        'solargraph/source_map/mapper'
    autoload :Clip,          'solargraph/source_map/clip'
    autoload :Completion,    'solargraph/source_map/completion'
    autoload :Region,        'solargraph/source_map/region'

    # @return [Source]
    attr_reader :source

    # @return [Array<Pin::Base>]
    attr_reader :pins

    # @return [Array<Pin::Base>]
    attr_reader :locals

    # @param source [Source]
    # @param pins [Array<Pin::Base>]
    # @param locals [Array<Pin::Base>]
    def initialize source, pins, locals
      # HACK: Keep the library from changing this
      @source = source.dup
      @pins = pins
      @locals = locals
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
      @requires ||= pins.select{|p| p.kind == Pin::REQUIRE_REFERENCE}
    end

    # @return [Array<Pin::Base>]
    def document_symbols
      @document_symbols ||= pins.select { |pin|
        [Pin::ATTRIBUTE, Pin::CONSTANT, Pin::METHOD, Pin::NAMESPACE].include?(pin.kind) and !pin.path.empty?
      }
    end

    # @param query [String]
    # @return [Array<Pin::Base>]
    def query_symbols query
      document_symbols.select{ |pin| fuzzy_string_match(pin.path, query) || fuzzy_string_match(pin.name, query) }
    end

    # @param position [Position]
    # @return [Solargraph::SourceMap::Fragment]
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
      pins.select { |pin| pin.location == location }
    end

    def locate_named_path_pin line, character
      _locate_pin line, character, Pin::NAMESPACE, Pin::METHOD
    end

    def locate_block_pin line, character
      _locate_pin line, character, Pin::NAMESPACE, Pin::METHOD, Pin::BLOCK
    end

    # @param other_map [SourceMap]
    # @return [Boolean]
    def try_merge! other_map
      return false if pins.length != other_map.pins.length || locals.length != other_map.locals.length || requires.map(&:name).uniq.sort != other_map.requires.map(&:name).uniq.sort
      pins.each_index do |i|
        return false unless pins[i].try_merge!(other_map.pins[i])
      end
      locals.each_index do |i|
        return false unless locals[i].try_merge!(other_map.locals[i])
      end
      @source = other_map.source
      true
    end

    # @param name [String]
    # @return [Array<Location>]
    def references name
      source.references name
    end

    def locals_at(location)
      return [] if location.filename != filename
      locals.select { |pin| pin.visible_at?(location) }
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

      # @param source [Source]
      # @return [SourceMap]
      def map source
        result = SourceMap::Mapper.map(source)
        new(source, *result)
      end
    end

    private

    # @param line [Integer]
    # @param character [Integer]
    # @param *kinds [Array<Symbol>]
    # @return [Pin::Base]
    def _locate_pin line, character, *kinds
      position = Position.new(line, character)
      found = nil
      pins.each do |pin|
        found = pin if (kinds.empty? || kinds.include?(pin.kind)) && pin.location.range.contain?(position)
        break if pin.location.range.start.line > line
      end
      # Assuming the root pin is always valid
      found || pins.first
    end

    # @param str1 [String]
    # @param str2 [String]
    # @return [Boolean]
    def fuzzy_string_match str1, str2
      JaroWinkler.distance(str1, str2) > 0.6
    end
  end
end
