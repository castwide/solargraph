module Solargraph

  class Position
    # @return [Integer]
    attr_reader :line

    # @return [Integer]
    attr_reader :character

    def initialize line, character
      @line = line
      @character = character
    end

    def column
      character
    end

    # Get a hash of the position. This representation is suitable for use in
    # the language server protocol.
    #
    # @return [Hash]
    def to_hash
      {
        line: line,
        character: character
      }
    end

    # Get a numeric offset for the specified text and position.
    #
    # @param text [String]
    # @param position [Position]
    # @return [Integer]
    def self.to_offset text, position
      result = 0
      feed = 0
      line = position.line
      column = position.character
      text.lines.each do |l|
        line_length = l.length
        char_length = l.chomp.length
        if feed == line
          result += column
          break
        end
        result += line_length
        feed += 1
      end
      result
    end

    # Get a numeric offset for the specified text and a position identified
    # by its line and character.
    #
    # @param text [String]
    # @param line [Integer]
    # @param character [Integer]
    # @return [Integer]
    def self.line_char_to_offset text, line, character
      to_offset(text, Position.new(line, character))
    end

    # Get a position for the specified text and offset.
    #
    # @param text [String]
    # @param offset [Integer]
    # @return [Position]
    def self.from_offset text, offset
      cursor = 0
      line = 0
      character = nil
      text.lines.each do |l|
        line_length = l.length
        char_length = l.chomp.length
        if cursor + char_length >= offset
          character = offset - cursor
          break
        end
        cursor += line_length
        line += 1
      end
      character = 0 if character.nil? and offset == cursor
      raise InvalidOffsetError if character.nil?
      Position.new(line, character)
    end

    def self.normalize object
      return object if object.is_a?(Position)
      return Position.new(object[0], object[1]) if object.is_a?(Array)
      raise ArgumentError, "Unable to convert #{object.class} to Position"
    end

    def == other
      return false unless other.is_a?(Position)
      line == other.line and character == other.character
    end
  end
end
