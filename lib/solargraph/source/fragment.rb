module Solargraph
  class Source
    # Information about a location in a source, including the location's word
    # and signature, literal values at the base of signatures, and whether the
    # location is inside a string or comment. ApiMaps use Fragments to provide
    # results for completion and definition queries.
    #
    class Fragment
      include NodeMethods

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

      # Get the fully qualified namespace at the current offset.
      #
      # @return [String]
      def namespace
        if @namespace.nil?
          pin = @source.locate_namespace_pin(line, character)
          @namespace = (pin.nil? ? '' : pin.path)
        end
        @namespace
      end

      # True if the fragment is inside a method argument.
      #
      # @return [Boolean]
      def argument?
        @argument ||= !signature_position.nil?
      end

      # @return [Fragment]
      def recipient
        return nil if signature_position.nil?
        @recipient ||= @source.fragment_at(*signature_position)
      end

      # Get the scope at the current offset.
      #
      # @return [Symbol] :class or :instance
      def scope
        if @scope.nil?
          @scope = :class
          @scope = :instance if named_path.kind == Pin::METHOD and named_path.scope == :instance
        end
        @scope
      end

      # Get the signature up to the current offset. Given the text `foo.bar`,
      # the signature at offset 5 is `foo.b`.
      #
      # @return [String]
      def signature
        @signature ||= signature_data[1]
      end

      def valid?
        @source.parsed?
      end

      def broken?
        !valid?
      end

      # Get the signature before the current word. Given the signature
      # `String.new.split`, the base is `String.new`.
      #
      # @return [String]
      def base
        if @base.nil?
          if signature.include?('.')
            if signature.end_with?('.')
              @base = signature[0..-2]
            else
              @base = signature.split('.')[0..-2].join('.')
            end
          elsif signature.include?('::')
            if signature.end_with?('::')
              @base = signature[0..-3]
            else
              @base = signature.split('::')[0..-2].join('::')
            end
          else
            # @base = signature
            @base = ''
          end
        end
        @base
      end

      # @return [String]
      def root
        @root ||= signature.split('.').first
      end

      # @return [String]
      def chain
        @chain ||= signature.split('.')[1..-1].join('.')
      end

      # @return [String]
      def base_chain
        @base_chain ||= signature.split('.')[1..-2].join('.')
      end

      # @return [String]
      def whole_chain
        @whole_chain ||= whole_signature.split('.')[1..-1].join('.')
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
        @whole_word ||= word + remainder.to_s
      end

      # Get the whole signature at the current offset, including the final
      # word and its remainder.
      #
      # @return [String]
      def whole_signature
        @whole_signature ||= signature + remainder
      end

      # Get the entire phrase up to the current offset. Given the text
      # `foo[bar].baz()`, the phrase at offset 10 is `foo[bar].b`.
      #
      # @return [String]
      def phrase
        @phrase ||= @code[signature_data[0]..offset]
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

      # @return [Solargraph::Pin::Base]
      def block
        @block ||= @source.locate_block_pin(line, character)
      end

      # @return [Solargraph::Pin::Base]
      def named_path
        @named_path ||= @source.locate_named_path_pin(line, character)
      end

      # @return [Array<Solargraph::Pin::Base>]
      def locals
        @locals ||= @source.locals.select{|pin| pin.visible_from?(block, position)}
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

      def get_position_at(offset)
        pos = Position.from_offset(@code, offset)
        [pos.line, pos.character]
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

      # True if the line and column are inside the specified range.
      #
      # @param location [Parser::Source::Range]
      def compare_range line, column, location
        return true if line == location.first_line and line == location.last_line and column >= location.column and column < location.last_column
        return true if line > location.first_line and line < location.last_line
        return true if line == location.last_line and column >= location.last_column and column < location.last_column
        false
      end

      # Select the word that directly precedes the specified index.
      # A word can only consist of letters, numbers, and underscores.
      #
      # @param index [Integer]
      # @return [String]
      def word_at index
        @code[beginning_of_word_at(index)..index - 1]
      end

      def beginning_of_word_at index
        cursor = index - 1
        # Words can end with ? or !
        if @code[cursor, 1] == '!' or @code[cursor, 1] == '?'
          cursor -= 1
        end
        while cursor > -1
          char = @code[cursor, 1]
          break if char.nil? or char.strip.empty?
          break unless char.match(/[a-z0-9_]/i)
          cursor -= 1
        end
        # Words can begin with @@, @, $, or :
        if cursor > -1
          if cursor > 0 and @code[cursor - 1, 2] == '@@'
            cursor -= 2
          elsif @code[cursor, 1] == '@' or @code[cursor, 1] == '$'
            cursor -= 1
          elsif @code[cursor, 1] == ':' and (cursor == 0 or @code[cursor - 1, 2] != '::')
            cursor -= 1
          end
        end
        cursor + 1
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

      def remainder_at index
        cursor = index
        while cursor < @code.length
          char = @code[cursor, 1]
          break if char.nil? or char == ''
          break unless char.match(/[a-z0-9_\?\!]/i)
          cursor += 1
        end
        @code[index..cursor-1]
      end

      def signature_position
        if @signature_position.nil?
          open_parens = 0
          cursor = offset - 1
          while cursor >= 0
            break if cursor < 0
            if @code[cursor] == ')'
              open_parens -= 1
            elsif @code[cursor] == '('
              open_parens += 1
            end
            break if open_parens == 1
            cursor -= 1
          end
          if cursor >= 0
            @signature_position = get_position_at(cursor)
          end
        end
        @signature_position
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
