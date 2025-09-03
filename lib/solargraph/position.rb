# frozen_string_literal: true

module Solargraph
  # The zero-based line and column numbers of a position in a string.
  #
  class Position
    include Equality

    # @return [Integer]
    attr_reader :line

    # @return [Integer]
    attr_reader :character

    alias column character

    # @param line [Integer]
    # @param character [Integer]
    def initialize line, character
      @line = line
      @character = character
    end

    # @sg-ignore Fix "Not enough arguments to Module#protected"
    protected def equality_fields
      [line, character]
    end

    # @param other [Position]
    def <=>(other)
      return nil unless other.is_a?(Position)
      if line == other.line
        character <=> other.character
      else
        line <=> other.line
      end
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

    def inspect
      "#<#{self.class} #{line}, #{character}>"
    end

    # Get a numeric offset for the specified text and position.
    #
    # @param text [String]
    # @param position [Position]
    # @return [Integer]
    def self.to_offset text, position
      return 0 if text.empty?
      cursor = 0
      index = -1
      text.each_line do |line|
        index += 1
        break if index == position.line
        cursor += line.length
      end
      cursor + position.character
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
      text.each_line do |l|
        line_length = l.length

        if l.end_with?("\n") || l.end_with?("\r\n")
          char_length = line_length - 1
        else
          char_length = line_length
        end

        if cursor + char_length >= offset
          character = offset - cursor
          break
        end
        cursor += line_length
        line += 1
      end
      character = 0 if character.nil? and (cursor - offset).between?(0, 1)
      raise InvalidOffsetError if character.nil?
      Position.new(line, character)
    end

    # A helper method for generating positions from arrays of integers. The
    # original parameter is returned if it is already a position.
    #
    # @raise [ArgumentError] if the object cannot be converted to a position.
    #
    # @param object [Position, Array(Integer, Integer)]
    # @return [Position]
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
