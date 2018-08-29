module Solargraph
  class Source
    # Information about a location in a source, including the location's word
    # and signature, literal values at the base of signatures, and whether the
    # location is inside a string or comment. ApiMaps use Fragments to provide
    # results for completion and definition queries.
    #
    class CallChainer
      include NodeMethods

      class << self
        # @param source [Source]
        # @param line [Integer]
        # @param column [Integer]
        # @return [Source::Chain]
        def chain source, line, column
          CallChainer.new(source, line, column).chain
        end
      end

      # @param source [Solargraph::Source]
      # @param line [Integer]
      # @param column [Integer]
      def initialize source, line, column
        @source = source
        @code = source.code
        @line = line
        @column = column
        @calculated_literal = false
      end

      # @return [Source::Chain]
      def chain
        links = []
        # @todo Smelly colon handling
        if @source.code[0..offset-1].end_with?(':') and !@source.code[0..offset-1].end_with?('::')
          links.push Chain::Link.new
        else
          links.push Chain::Literal.new(base_literal) if base_literal?
          sig = whole_signature
          sig = sig[1..-1] if sig.start_with?('.') and base_literal?
          sig.split('.', -1).each do |word|
            if word.include?('::')
              # @todo Smelly way of handling constants
              parts = (word.start_with?('::') ? word[2..-1] : word).split('::', -1)
              last = parts.pop
              links.push Chain::Constant.new(parts.join('::')) unless parts.empty?
              links.push (last.nil? ? Chain::UNDEFINED_CONSTANT : Chain::Constant.new(last))
            else
              links.push word_to_link(word)
            end
          end
        end
        @chain ||= Chain.new(source.filename, links)
      end

      # private

      def word_to_link word
        if word.start_with?('@@')
          Chain::ClassVariable.new(word)
        elsif word.start_with?('@')
          Chain::InstanceVariable.new(word)
        elsif word.start_with?('$')
          Chain::GlobalVariable.new(word)
        elsif word.end_with?(':')
          Chain::Link.new
        elsif word.empty?
          Chain::UNDEFINED_CALL
        else
          Chain::Call.new(word)
        end
      end

      # The zero-based line number of the fragment's location.
      #
      # @return [Integer]
      attr_reader :line

      # The zero-based column number of the fragment's location.
      #
      # @return [Integer]
      attr_reader :column

      # @return [Solargraph::Source]
      attr_reader :source

      # An alias for #column.
      #
      # @return [Integer]
      def character
        @column
      end

      # @return [Source::Position]
      def position
        @position ||= Position.new(line, column)
      end

      # Get the signature up to the current offset. Given the text `foo.bar`,
      # the signature at offset 5 is `foo.b`.
      #
      # @return [String]
      def signature
        @signature ||= signature_data[1].to_s
      end

      # Get the remainder of the word after the current offset. Given the text
      # `foobar` with an offset of 3, the remainder is `bar`.
      #
      # @return [String]
      def remainder
        @remainder ||= remainder_at(offset)
      end

      # Get the whole word at the current offset, including the remainder.
      # Given the text `foobar.baz`, the whole word at any offset from 0 to 6
      # is `foobar`.
      #
      # @return [String]
      def whole_word
        @whole_word ||= word + remainder
      end

      # Get the whole signature at the current offset, including the final
      # word and its remainder.
      #
      # @return [String]
      def whole_signature
        @whole_signature ||= signature + remainder
      end

      # Get the word before the current offset. Given the text `foo.bar`, the
      # word at offset 6 is `ba`.
      #
      # @return [String]
      def word
        @word ||= word_at(offset)
      end

      # True if the current offset is inside a string.
      #
      # @return [Boolean]
      def string?
        # @string ||= (node.type == :str or node.type == :dstr)
        @string ||= @source.string_at?(line, character)
      end

      # True if the current offset is inside a comment.
      #
      # @return [Boolean]
      def comment?
        @comment ||= check_comment(line, column)
      end

      # Get the range of the word up to the current offset.
      #
      # @return [Range]
      def word_range
        @word_range ||= word_range_at(offset, false)
      end

      # Get the range of the whole word at the current offset, including its
      # remainder.
      #
      # @return [Range]
      def whole_word_range
        @whole_word_range ||= word_range_at(offset, true)
      end

      # True if the fragment is a signature that stems from a literal value.
      #
      # @return [Boolean]
      def base_literal?
        !base_literal.nil?
      end

      # The type of literal value at the root of the signature (or nil).
      #
      # @return [String]
      def base_literal
        if @base_literal.nil? and !@calculated_literal
          @calculated_literal = true
          if signature.start_with?('.')
            pn = @source.node_at(line, column - 2)
            @base_literal = infer_literal_node_type(pn) unless pn.nil?
          end
        end
        @base_literal
      end

      # True if the fragment is inside a literal value.
      #
      # @return [Boolean]
      def literal?
        !literal.nil?
      end

      # The fragment's literal type, or nil if the fragment is not inside a
      # literal value.
      #
      # @return [String]
      def literal
        if @literal.nil? and !@calculated_actual_literal
          @calculated_actual_literal = true
          pn = @source.node_at(line, column)
          @literal = infer_literal_node_type(pn)
        end
      end

      private

      # @return [Integer]
      def offset
        @offset ||= get_offset(line, column)
      end

      def get_offset line, column
        Position.line_char_to_offset(@code, line, column)
      end

      def signature_data
        @signature_data ||= get_signature_data_at(offset)
      end

      def get_signature_data_at index
        brackets = 0
        squares = 0
        parens = 0
        signature = ''
        index -=1
        in_whitespace = false
        while index >= 0
          pos = Position.from_offset(@code, index)
          break if index > 0 and check_comment(pos.line, pos.character)
          unless !in_whitespace and string?
            break if brackets > 0 or parens > 0 or squares > 0
            char = @code[index, 1]
            break if char.nil? # @todo Is this the right way to handle this?
            if brackets.zero? and parens.zero? and squares.zero? and [' ', "\r", "\n", "\t"].include?(char)
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
                signature = ".[]#{signature}" if parens.zero? and brackets.zero? and squares.zero? and @code[index-2] != '%'
              end
              if brackets.zero? and parens.zero? and squares.zero?
                break if ['"', "'", ',', ';', '%'].include?(char)
                signature = char + signature if char.match(/[a-z0-9:\._@\$\?\!]/i) and @code[index - 1] != '%'
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
        # @todo Smelly exceptional case for integer literals
        match = signature.match(/^[0-9]+/)
        if match
          index += match[0].length
          signature = signature[match[0].length..-1].to_s
          @base_literal = 'Integer'
        # @todo Smelly exceptional case for array literals
        elsif signature.start_with?('.[]')
          index += 2
          signature = signature[3..-1].to_s
          @base_literal = 'Array'
        elsif signature.start_with?('.')
          pos = Position.from_offset(source.code, index)
          node = source.node_at(pos.line, pos.character)
          lit = infer_literal_node_type(node)
          unless lit.nil?
            signature = signature[1..-1].to_s
            index += 1
            @base_literal = lit
          end
        end
        [index + 1, signature]
      end

      # Determine if the specified location is inside a comment.
      #
      # @param lin [Integer]
      # @param col [Integer]
      # @return [Boolean]
      def check_comment(lin, col)
        index = Position.line_char_to_offset(source_from_parser, lin, col)
        @source.comments.each do |c|
          return true if index > c.location.expression.begin_pos and index <= c.location.expression.end_pos
        end
        false
      end

      # @return Solargraph::Source::Range
      def word_range_at index, whole
        cursor = beginning_of_word_at(index)
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
        start_pos = get_position_at(start_offset)
        end_pos = get_position_at(end_offset)
        Solargraph::Source::Range.from_to(start_pos[0], start_pos[1], end_pos[0], end_pos[1])
      end

      # @return [String]
      def remainder_at index
        cursor = index
        while cursor < @code.length
          char = @code[cursor, 1]
          break if char.nil? or char == ''
          break unless char.match(/[a-z0-9_\?\!]/i)
          cursor += 1
        end
        @code[index..cursor-1].to_s
      end

      # Range tests that depend on positions identified from parsed code, such
      # as comment ranges, need to normalize EOLs to \n.
      #
      # @return [String]
      def source_from_parser
        @source_from_parser ||= @source.code.gsub(/\r\n/, "\n")
      end
    end
  end
end
