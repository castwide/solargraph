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

    # @param position [Position, Array(Integer, Integer)]
    # @return [Boolean]
    def string_at? position
      position = Position.normalize(position)
      @source.string_at?(position)
    end

    # @param position [Position, Array(Integer, Integer)]
    # @return [Boolean]
    def comment_at? position
      position = Position.normalize(position)
      @source.comment_at?(position)
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
      document_symbols.select{|pin| pin.path.include?(query)}
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
    # @return [Solargraph::Pin::Base]
    def locate_pin location
      # return nil unless location.start_with?("#{filename}:")
      pins.select{|pin| pin.location == location}.first
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
      # @todo Assuming the root pin is always valid
      found || pins.first
    end
  end
end
