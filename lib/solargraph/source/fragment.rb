module Solargraph
  class Source
    class Fragment
      def initialize source, offset
        # @todo Split this object from the source. The source can change; if
        #   it does, this object's data should not.
        @source = source
        @node = source.node
        @code = source.code
        @offset = offset
      end

      def signature_start
        signature_data[0]
      end

      def signature
        signature_data[1]
      end

      def phrase
        @phrase ||= @code[signature_data[0]..@offset]
      end

      def word
        @word ||= word_at(@offset)
      end

      def signature_data
        @signature_data ||= get_signature_data_at(@offset)
      end

      def string?
        @string = @source.string_at?(@offset) if @string.nil?
        @string
      end

      def comment?
        @comment = get_comment_at(@offset) if @comment.nil?
        @comment
      end

      def word_range
        @word_range ||= word_range_at(@offset, false)
      end

      def whole_word_range
        @whole_word_range ||= word_range_at(@offset, true)
      end

      private

      def get_signature_data_at index
        brackets = 0
        squares = 0
        parens = 0
        signature = ''
        index -=1
        in_whitespace = false
        while index >= 0
          break if index > 0 and comment?
          unless !in_whitespace and string?
            break if brackets > 0 or parens > 0 or squares > 0
            char = @code[index, 1]
            if brackets.zero? and parens.zero? and squares.zero? and [' ', "\n", "\t"].include?(char)
              in_whitespace = true
            else
              if brackets.zero? and parens.zero? and squares.zero? and in_whitespace
                unless char == '.' or @code[index+1..-1].strip.start_with?('.')
                  old = @code[index+1..-1]
                  nxt = @code[index+1..-1].lstrip
                  index += (@code[index+1..-1].length - @code[index+1..-1].lstrip.length)
                  break
                end
              end
              if char == ')'
                parens -=1
              elsif char == ']'
                squares -=1
              elsif char == '}'
                brackets -= 1
              elsif char == '('
                parens += 1
              elsif char == '{'
                brackets += 1
              elsif char == '['
                squares += 1
                signature = ".[]#{signature}" if squares == 0 and @code[index-2] != '%'
              end
              if brackets.zero? and parens.zero? and squares.zero?
                break if ['"', "'", ',', ';', '%'].include?(char)
                signature = char + signature if char.match(/[a-z0-9:\._@\$]/i) and @code[index - 1] != '%'
                break if char == '$'
                if char == '@'
                  signature = "@#{signature}" if @code[index-1, 1] == '@'
                  break
                end
              end
              in_whitespace = false
            end
          end
          index -= 1
        end
        signature = signature[1..-1] if signature.start_with?('.')
        [index + 1, signature]
      end  

      # Determine if the specified index is inside a comment.
      #
      # @return [Boolean]
      def get_comment_at(index)
        return false if string?
        line, col = Solargraph::Source.get_position_at(@source.code, index)
        # return false if source.stubbed_lines.include?(line)
        @source.comments.each do |c|
          return true if index > c.location.expression.begin_pos and index <= c.location.expression.end_pos
        end
        # Extra test due to some comments not getting tracked
        while (index >= 0 and @code[index] != "\n")
          return false if string?
          if @code[index] == '#'
            return true if index == 0
            return false if string?
            return true unless @code[index-1, 3] == '"#{'
          end
          index -= 1
        end
        false
      end

      # Select the word that directly precedes the specified index.
      # A word can only consist of letters, numbers, and underscores.
      #
      # @param index [Integer]
      # @return [String]
      def word_at index
        word = ''
        cursor = index - 1
        while cursor > -1
          char = @code[cursor, 1]
          break if char.nil? or char == ''
          word = char + word if char == '$'
          break unless char.match(/[a-z0-9_]/i)
          word = char + word
          cursor -= 1
        end
        word
      end

      def word_range_at index, whole
        cursor = index
        while cursor > -1
          char = @code[cursor - 1, 1]
          break if char.nil? or char == ''
          break unless char.match(/[a-z0-9_@$]/i)
          cursor -= 1
        end
        start_offset = cursor
        start_offset -= 1 if (start_offset > 1 and @code[start_offset - 1] == ':') and (start_offset == 1 or @code[start_offset - 2] != ':')
        cursor = index
        if whole
          while cursor < @code.length
            char = @code[cursor, 1]
            break if char.nil? or char == ''
            break unless char.match(/[a-z0-9_\?\!]/i)
            cursor += 1
          end
        end
        end_offset = cursor
        end_offset = start_offset if end_offset < start_offset
        start_pos = Solargraph::Source.get_position_at(@code, start_offset)
        end_pos = Solargraph::Source.get_position_at(@code, end_offset)
        result = {
          start: {
            line: start_pos[0],
            character: start_pos[1]
          },
          end: {
            line: end_pos[0],
            character: end_pos[1]
          }
        }
        result
      end  
    end
  end
end
