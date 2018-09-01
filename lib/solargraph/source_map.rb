module Solargraph
  class SourceMap
    autoload :Mapper,        'solargraph/source_map/mapper'
    autoload :Fragment,      'solargraph/source_map/fragment'
    autoload :Chain,         'solargraph/source_map/chain'
    autoload :Clip,          'solargraph/source_map/clip'
    autoload :SourceChainer, 'solargraph/source_map/source_chainer'
    autoload :NodeChainer,   'solargraph/source_map/node_chainer'
    autoload :Completion,    'solargraph/source_map/completion'

    attr_reader :source

    attr_reader :pins

    attr_reader :locals

    attr_reader :requires

    def initialize source, pins, locals, requires, symbols, string_ranges, comment_ranges
      # [@source, @pins, @locals, @requires, @symbols, @string_ranges, @comment_ranges]
      @source = source
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
      string_ranges.each do |range|
        return true if range.contain?(position)
        break if range.ending.line > position.line
      end
      false
    end

    # @param position [Position]
    # @return [Boolean]
    def comment_at? position
      comment_ranges.each do |range|
        return true if range.contain?(position)
        break if range.ending.line > position.line
      end
      false
    end

    def document_symbols
      @api_symbols ||= pins.select { |pin|
        [Pin::ATTRIBUTE, Pin::CONSTANT, Pin::METHOD, Pin::NAMESPACE].include?(pin.kind) and !pin.path.empty?
      }
    end

    # @param position [Position]
    # @return [Solargraph::SourceMap::Fragment]
    def fragment_at position
      Fragment.new(self, position)
    end

    # @param location [Solargraph::Source::Location]
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
      return false if pins.length != other_map.pins.length or locals.length != other_map.locals.length
      pins.each_index do |i|
        return false unless pins[i].try_merge!(other_map.pins[i])
      end
      locals.each_index do |i|
        return false unless  locals[i].try_merge!(other_map.locals[i])
      end
      @source = other_map.source
      true
    end

    class << self
      def load filename
        source = Solargraph::Source.load(filename)
        SourceMap.map(source)
      end

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
