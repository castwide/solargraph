module Solargraph
  class SourceMap
    autoload :Mapper,        'solargraph/source_map/mapper'
    autoload :Clip,          'solargraph/source_map/clip'
    autoload :Completion,    'solargraph/source_map/completion'
    autoload :NewFragment,   'solargraph/source_map/new_fragment'

    attr_reader :source

    # @return [Array<Pin::Base>]
    attr_reader :pins

    attr_reader :locals

    attr_reader :requires

    def initialize source, pins, locals, requires, symbols, string_ranges, comment_ranges
      # HACK: Keep the library from changing this
      @source = source.dup
      @pins = pins
      @locals = locals
      @requires = requires
      @pins.concat symbols
      @string_ranges = string_ranges
      @comment_ranges = comment_ranges
    end

    def filename
      source.filename
    end

    def code
      source.code
    end

    # @param position [Position]
    # @return [Boolean]
    def string_at? position
      @source.string_at?(position)
    end

    # @param position [Position]
    # @return [Boolean]
    def comment_at? position
      @source.comment_at?(position)
    end

    def document_symbols
      @document_symbols ||= pins.select { |pin|
        [Pin::ATTRIBUTE, Pin::CONSTANT, Pin::METHOD, Pin::NAMESPACE].include?(pin.kind) and !pin.path.empty?
      }
    end

    def query_symbols query
      document_symbols.select{|pin| pin.path.include?(query)}
    end

    # @param position [Position]
    # @return [Solargraph::SourceMap::Fragment]
    def cursor_at position
      Source::Cursor.new(source, position)
    end

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

    def try_merge! other_map
      return false if pins.length != other_map.pins.length || locals.length != other_map.locals.length
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
      # @return [SourceMap]
      def load filename
        source = Solargraph::Source.load(filename)
        SourceMap.map(source)
      end

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

    # @return [Array<Range>]
    attr_reader :string_ranges

    # @return [Array<Range>]
    attr_reader :comment_ranges

    def _locate_pin line, character, *kinds
      position = Position.new(line, character)
      found = nil
      pins.each do |pin|
        found = pin if (kinds.empty? or kinds.include?(pin.kind)) and pin.location.range.contain?(position)
        break if pin.location.range.start.line > line
      end
      # @todo Assuming the root pin is always valid
      found || pins.first
    end
  end
end
