# frozen_string_literal: true

module Solargraph
  # A pointer to a section of source text identified by its filename
  # and Range.
  #
  class Location
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

    # @return [Hash]
    def to_hash
      {
        filename: filename,
        range: range.to_hash
      }
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
