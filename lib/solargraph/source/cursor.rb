module Solargraph
  class Source
    # Information about a position in a source, including the word located
    # there.
    #
    class Cursor
      # @return [Position]
      attr_reader :position

      # @return [Source]
      attr_reader :source

      # @param source [Source]
      # @param position [Position, Array(Integer, Integer)]
      def initialize source, position
        @source = source
        @position = Position.normalize(position)
      end

      # @return [String]
      def filename
        source.filename
      end

      # The whole word at the current position. Given the text `foo.bar`, the
      # word at position(0,6) is `bar`.
      #
      # @return [String]
      def word
        @word ||= start_of_word + end_of_word
      end

      # The part of the word before the current position. Given the text
      # `foo.bar`, the start_of_word at position(0, 6) is `ba`.
      #
      # @return [String]
      def start_of_word
        @start_of_word ||= begin
          match = source.code[0..offset-1].to_s.match(start_word_pattern)
          result = (match ? match[0] : '')
          # Including the preceding colon if the word appears to be a symbol
          result = ":#{result}" if source.code[0..offset-result.length-1].end_with?(':') and !source.code[0..offset-result.length-1].end_with?('::')
          result
        end
      end

      # The part of the word after the current position. Given the text
      # `foo.bar`, the end_of_word at position (0,6) is `r`.
      #
      # @return [String]
      def end_of_word
        @end_of_word ||= begin
          match = source.code[offset..-1].to_s.match(end_word_pattern)
          match ? match[0] : ''
        end
      end

      def start_of_constant?
        source.code[offset-2, 2] == '::'
      end

      # The range of the word at the current position.
      #
      # @return [Range]
      def range
        @range ||= begin
          s = Position.from_offset(source.code, offset - start_of_word.length)
          e = Position.from_offset(source.code, offset + end_of_word.length)
          Solargraph::Range.new(s, e)
        end
      end

      # @return [Chain]
      def chain
        @chain ||= SourceChainer.chain(source, position)
      end

      # True if the statement at the cursor is an argument to a previous
      # method.
      #
      # Given the code `process(foo)`, a cursor pointing at `foo` would
      # identify it as an argument being passed to the `process` method.
      #
      # If #argument? is true, the #recipient method will return a cursor that
      # points to the method receiving the argument.
      #
      # @return [Boolean]
      def argument?
        # @argument ||= !signature_position.nil?
        @argument ||= !recipient.nil?
      end

      # @return [Boolean]
      def comment?
        @comment ||= source.comment_at?(position)
      end

      # @return [Boolean]
      def string?
        @string ||= source.string_at?(position)
      end

      # Get a cursor pointing to the method that receives the current statement
      # as an argument.
      #
      # @return [Cursor, nil]
      def recipient
        @recipient ||= begin
          result = nil
          node = recipient_node
          unless node.nil?
            result = if node.children[1].is_a?(AST::Node)
                       pos = Range.from_node(node.children[1]).start
                       Cursor.new(source, Position.new(pos.line, pos.column - 1))
                     else
                       Cursor.new(source, Range.from_node(node).ending)
                     end
          end
          result
        end
      end

      def node_position
        @node_position ||= begin
          if start_of_word.empty?
            match = source.code[0, offset].match(/[\s]*(\.|:+)[\s]*$/)
            if match
              Position.from_offset(source.code, offset - match[0].length)
            else
              position
            end
          else
            position
          end
        end
      end

      # @return [Parser::AST::Node, nil]
      def recipient_node
        return nil if source.code[offset-1] == ')'
        return nil if first_char_offset < offset && source.code[first_char_offset..offset-1] =~ /\)[\s]*\Z/
        pos = Position.from_offset(source.code, first_char_offset)
        tree = source.tree_at(pos.line, pos.character)
        if tree[0] && tree[0].type == :send
          rng = Range.from_node(tree[0])
          return tree[0] if (rng.contain?(position) || offset + 1 == Position.to_offset(source.code, rng.ending)) && source.code[offset] =~ /[ \t\)\,'")]/
          return tree[0] if (source.code[0..offset-1] =~ /\([\s]*\Z/ || source.code[0..offset-1] =~ /[a-z0-9_][ \t]+\Z/i)
        end
        return tree[1] if tree[1] && tree[1].type == :send
        return tree[3] if tree[1] && tree[3] && tree[1].type == :pair && tree[3].type == :send
        nil
      end

      private

      # @return [Integer]
      def offset
        @offset ||= Position.to_offset(source.code, position)
      end

      def first_char_offset
        @first_char_position ||= begin
          if source.code[offset - 1] == ')'
            position
          else
            index = offset - 1
            index -= 1 while index > 0 && source.code[index].strip.empty?
            index
          end
        end
      end

      # A regular expression to find the start of a word from an offset.
      #
      # @return [Regexp]
      def start_word_pattern
        /(@{1,2}|\$)?([a-z0-9_]|[^\u0000-\u007F])*\z/i
      end

      # A regular expression to find the end of a word from an offset.
      #
      # @return [Regexp]
      def end_word_pattern
        /^([a-z0-9_]|[^\u0000-\u007F])*[\?\!]?/i
      end

      def signature_position
        if @signature_position.nil?
          open_parens = 0
          cursor = offset - 1
          while cursor >= 0
            break if cursor < 0
            if source.code[cursor] == ')'
              open_parens -= 1
            elsif source.code[cursor] == '('
              open_parens += 1
            end
            break if open_parens == 1
            cursor -= 1
          end
          if cursor >= 0
            @signature_position = Position.from_offset(source.code, cursor)
          end
        end
        @signature_position
      end
    end
  end
end
