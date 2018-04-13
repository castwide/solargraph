module Solargraph

  class Source
    class Position
      # @return [Integer]
      attr_reader :line

      # @return [Integer]
      attr_reader :character

      def initialize line, character
        @line = line
        @character = character
      end

      # Get a hash of the position. This representation is suitable for use in
      # the language server protocol.
      #
      def to_hash
        {
          line: line,
          character: character
        }
      end

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

      def self.line_char_to_offset text, line, character
        to_offset(text, Position.new(line, character))
      end

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
    end
  end
end
