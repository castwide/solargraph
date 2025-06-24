# frozen_string_literal: true

module Solargraph
  # A pointer to a section of source text identified by its filename
  # and Range.
  #
  class Location
    include Equality

    # @return [String]
    attr_reader :filename

    # @return [Solargraph::Range]
    attr_reader :range

    # @param filename [String]
    # @param range [Solargraph::Range]
    def initialize filename, range
      @filename = filename
      @range = range
    end

    # @sg-ignore Fix "Not enough arguments to Module#protected"
    protected def equality_fields
      [filename, range]
    end

    def <=>(other)
      return nil unless other.is_a?(Location)
      if filename == other.filename
        range <=> other.range
      else
        filename <=> other.filename
      end
    end

    def rbs?
      filename.end_with?('.rbs')
    end

    # @param location [self]
    def contain? location
      range.contain?(location.range.start) && range.contain?(location.range.ending) && filename == location.filename
    end

    def inspect
      "<#{self.class.name}: filename=#{filename}, range=#{range.inspect}>"
    end

    def to_s
      inspect
    end

    # @return [Hash]
    def to_hash
      {
        filename: filename,
        range: range.to_hash
      }
    end

    # @param node [Parser::AST::Node, nil]
    def self.from_node(node)
      return nil if node.nil? || node.loc.nil?
      range = Range.from_node(node)
      self.new(node.loc.expression.source_buffer.name, range)
    end

    # @param other [BasicObject]
    def == other
      return false unless other.is_a?(Location)
      filename == other.filename and range == other.range
    end

    def inspect
      "#<#{self.class} #{filename}, #{range.inspect}>"
    end
  end
end
