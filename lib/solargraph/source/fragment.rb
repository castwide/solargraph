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
      # @todo This method might need to change significantly or go away.
      #
      # @return [String]
      def signature
        # @signature ||= begin
        #   result = base
        #   if whole_signature == "#{base}.#{whole_word}"
        #     result += ".#{start_of_word}"
        #   else
        #     result += start_of_word
        #   end
        #   result += separator.strip
        #   result
        # end
        @signature ||= chain.links[1..-1].join('.')
      end


      # Get the signature before the current word. Given the signature
      # `String.new.split`, the base is `String.new`.
      #
      # @return [String]
      def base
        chain.links[0..-2].map(&:word).join('.')
      end

      # @return [Source::Chain]
      def chain
        @chain ||= generate_chain
      end

      # Get the remainder of the word after the current offset. Given the text
      # `foobar` with an offset of 3, the remainder is `bar`.
      #
      # @return [String]
      def remainder
        # @remainder ||= remainder_at(offset)
        end_of_word
      end

      # Get the whole word at the current offset, including the remainder.
      # Given the text `foobar.baz`, the whole word at any offset from 0 to 6
      # is `foobar`.
      #
      # @return [String]
      def whole_word
        word + remainder
      end

      # Get the whole signature at the current offset, including the final
      # word and its remainder.
      #
      # @return [String]
      def whole_signature
        chain.links.reject{|l| l.word == '<undefined>'}.map(&:word).join('.')
      end

      # Get the word before the current offset. Given the text `foo.bar`, the
      # word at offset 6 is `ba`.
      #
      # @return [String]
      def start_of_word
        # @word ||= word_at(offset)
        @start_of_word ||= begin
          match = @code[0..offset-1].to_s.match(start_word_pattern)
          result = (match ? match[0] : '')
          result = ":#{result}" if @code[0..offset-result.length].end_with?('::') and !@code[0..offset-result.length].end_with?('::')
          result
        end
      end

      def word
        start_of_word
      end

      def end_of_word
        @end_of_word ||= begin
          match = @code[offset..-1].to_s.match(end_word_pattern)
          match ? match[0] : ''
        end
      end

      def remainder
        end_of_word
      end

      def whole_word
        start_of_word + end_of_word
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
        @word_range ||= word_range_at(offset - start_of_word.length, offset)
      end

      # Get the range of the whole word at the current offset, including its
      # remainder.
      #
      # @return [Range]
      def whole_word_range
        @whole_word_range ||= word_range_at(offset - start_of_word.length, offset + end_of_word.length)
      end

      # @return [Solargraph::Pin::Base]
      def block
        @block ||= @source.locate_block_pin(line, character)
      end

      # @return [Solargraph::Pin::Base]
      def named_path
        @named_path ||= @source.locate_named_path_pin(line, character)
      end

      # Get an array of all the locals that are visible from the fragment's
      # position. Locals can be local variables, method parameters, or block
      # parameters. The array starts with the nearest local pin.
      #
      # @return [Array<Solargraph::Pin::Base>]
      def locals
        @locals ||= @source.locals.select{|pin| pin.visible_from?(block, position)}.reverse
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

      def define api_map
        chain.define_with(api_map, named_path, locals)
      end

      # @param api_map [ApiMap]
      # @return [ComplexType]
      def infer_base_type api_map
        chain.infer_base_type_with(api_map, named_path, locals)
      end

      def try_merge! new_line, new_column
        return false unless line == new_line and column < new_column and separator.empty?
        # @todo Should link words ever be nil?
        return false if chain.links.last.nil? or chain.links.last.word.nil? or chain.links.last.word == '<undefined>'
        text = source.at(Range.from_to(line, column, new_line, new_column))
        return true if column == new_column and text.empty?
        return false unless text =~ /^[a-z0-9_]*$/i
        # Update this fragment
        # @todo Figure out everything that needs to be done here
        start_of_word.concat text
        @column = new_column
        @offset += (new_column - column)
        chain.links.last.word.concat text
        @base_position = nil
        @signature = nil
        @word_range = nil
        @whole_word_range = nil
        @base_position = nil
        true
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
      def word_range_at first, last
        s = Position.from_offset(@source.code, first)
        e = Position.from_offset(@source.code, last)
        Solargraph::Source::Range.new(s, e)
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

      def generate_chain
        # return NodeChainer.chain(source, line, column) if source.parsed?
        # base_node = source.node_at(base_position.line, base_position.column)
        # code = source.from_to(base_node.loc.expression.line - 1, base_node.loc.expression.column, base_position.line, base_position.column + 1)
        # chain = Source::Chain.load_string(source.filename, code)
        # Add a "tail" to the chain to represent the unparsed section
        # chain.links.push(Chain::Link.new) unless separator.empty?
        CallChainer.chain(source, line, column)
      end

      def separator
        @separator ||= begin
          result = ''
          # if word.empty?
            adj = (column.zero? ? offset : offset - 1)
            match = source.code[0..adj].match(/[\s]*(\.{1}|:{2})[\s]*{1}\z/)
            result = match[0] if match
          # end
          result
        end
      end

      def base_offset
        @base_offset ||= offset - (separator.length + (column.zero? ? 0 : 1))
      end

      def base_position
        @base_position ||= Source::Position.from_offset(source.code, base_offset)
      end

      def start_word_pattern
        /(@{1,2}|\$)?([a-z0-9_]|[^\u0000-\u007F])*\z/i
      end

      def end_word_pattern
        /^([a-z0-9_]|[^\u0000-\u007F])*[\?\!]?/i
      end
    end
  end
end
