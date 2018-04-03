module Solargraph
  class Source
    class Fragment
      attr_reader :offset

      include NodeMethods

      def initialize source, offset
        # @todo Split this object from the source. The source can change; if
        #   it does, this object's data should not.
        @source = source
        @code = source.code
        @offset = offset
      end

      def node
        @node ||= @source.node_at(@offset)
      end

      def namespace
        if @namespace.nil?
          base = @source.parent_node_from(@offset, :class, :module, :def, :defs)
          @namespace ||= @source.namespace_for(base)
        end
        @namespace
      end

      def scope
        if @scope.nil?
          base = @source.parent_node_from(@offset, :class, :module, :def, :defs, :source)
          @scope = (base.type == :def ? :instance : :class)
        end
        @scope
      end

      def signature
        @signature ||= signature_data[1]
      end

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

      def remainder
        @remainder ||= remainder_at(@offset)
      end

      def whole_word
        @whole_word ||= word + remainder
      end

      def whole_signature
        @whole_signature ||= signature + remainder
      end

      def phrase
        @phrase ||= @code[signature_data[0]..@offset]
      end

      def word
        @word ||= word_at(@offset)
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

      def local_variable_pins
        @local_variable_pins ||= @source.local_variable_pins.select{|pin| pin.visible_from?(node)}
      end

      private

      def signature_data
        @signature_data ||= get_signature_data_at(@offset)
      end

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
        if signature.start_with?('.')
          pn = @source.node_at(index)
          unless pn.nil?
            literal = infer_literal_node_type(pn)
            unless literal.nil?
              signature = "#{literal}.new#{signature}"
              # @todo Determine the index from the beginning of the literal node?
            end
          end
        end
        [index + 1, signature]
      end  

      # Determine if the specified index is inside a comment.
      #
      # @return [Boolean]
      def get_comment_at(index)
        return false if string?
        line, col = Solargraph::Source.get_position_at(@source.code, index)
        @source.comments.each do |c|
          return true if index > c.location.expression.begin_pos and index <= c.location.expression.end_pos
        end
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
        start_pos = Solargraph::Source.get_position_at(@code, start_offset)
        end_pos = Solargraph::Source.get_position_at(@code, end_offset)
        # result = {
        #   start: {
        #     line: start_pos[0],
        #     character: start_pos[1]
        #   },
        #   end: {
        #     line: end_pos[0],
        #     character: end_pos[1]
        #   }
        # }
        # result
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

    end
  end
end
