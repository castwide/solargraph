module Solargraph
  class Source
    # Information about a location in a source, including the location's word
    # and signature, literal values at the base of signatures, and whether the
    # location is inside a string or comment. ApiMaps use Fragments to provide
    # results for completion and definition queries.
    #
    class SourceChainer
      include Source::NodeMethods

      private_class_method :new

      class << self
        # @param source [Source]
        # @param position [Position]
        # @return [Source::Chain]
        def chain source, position
          raise "Not a source" unless source.is_a?(Source)
          new(source, position).chain
        end
      end

      # @param source [Source]
      # @param position [Position]
      def initialize source, position
        @source = source
        # @source.code = source.code
        @position = position
        # @todo Get rid of line/column
        @line = position.line
        @column = position.column
        @calculated_literal = false
      end

      # @return [Source::Chain]
      def chain
        links = []
        # @todo Smelly colon handling
        if @source.code[0..offset-1].end_with?(':') and !@source.code[0..offset-1].end_with?('::')
          links.push Chain::Link.new
          links.push Chain::Link.new
        elsif @source.string_at?(position)
          links.push Chain::Literal.new('String')
        else
          links.push Chain::Literal.new(base_literal) if base_literal?
          sig = whole_signature
          unless sig.empty?
            sig = sig[1..-1] if sig.start_with?('.')
            head = true
            sig.split('.', -1).each do |word|
              if word.include?('::')
                # @todo Smelly way of handling constants
                parts = (word.start_with?('::') ? word[2..-1] : word).split('::', -1)
                last = parts.pop
                links.push Chain::Constant.new(parts.join('::')) unless parts.empty?
                links.push (last.nil? or last.empty? ? Chain::UNDEFINED_CONSTANT : Chain::Constant.new(last))
              else
                links.push word_to_link(word, head)
              end
              head = false
            end
          end
          # Literal string hack
          links.push Chain::UNDEFINED_CALL if base_literal? and @source.code[offset - 1] == '.' and links.length == 1
        end
        @chain ||= Chain.new(links)
      end

      private

      attr_reader :position

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

      def word_to_link word, head
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
        elsif head and !@source.code[signature_data[0]..-1].match(/^[\s]*?#{word}[\s]*?\(/)
          # The head needs to allow for ambiguous references to constants and
          # methods. For example, `String` might be either. If the word is not
          # followed by an open parenthesis, use Chain::Head for ambiguous
          # results.
          Chain::Head.new(word)
        else
          Chain::Call.new(word)
        end
      end

      # An alias for #column.
      #
      # @return [Integer]
      def character
        @column
      end

      # @return [Position]
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

      # Get the whole signature at the current offset, including the final
      # word and its remainder.
      #
      # @return [String]
      def whole_signature
        @whole_signature ||= signature + remainder
      end

      # True if the current offset is inside a string.
      #
      # @return [Boolean]
      def string?
        # @string ||= (node.type == :str or node.type == :dstr)
        @string ||= @source.string_at?(position)
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

      # @return [Integer]
      def offset
        @offset ||= get_offset(line, column)
      end

      def get_offset line, column
        Position.line_char_to_offset(@source.code, line, column)
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
          pos = Position.from_offset(@source.code, index)
          break if index > 0 and @source.comment_at?(pos)
          unless !in_whitespace and string?
            break if brackets > 0 or parens > 0 or squares > 0
            char = @source.code[index, 1]
            break if char.nil? # @todo Is this the right way to handle this?
            if brackets.zero? and parens.zero? and squares.zero? and [' ', "\r", "\n", "\t"].include?(char)
              in_whitespace = true
            else
              if brackets.zero? and parens.zero? and squares.zero? and in_whitespace
                unless char == '.' or @source.code[index+1..-1].strip.start_with?('.')
                  old = @source.code[index+1..-1]
                  nxt = @source.code[index+1..-1].lstrip
                  index += (@source.code[index+1..-1].length - @source.code[index+1..-1].lstrip.length)
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
                signature = ".[]#{signature}" if parens.zero? and brackets.zero? and squares.zero? and @source.code[index-2] != '%'
              end
              if brackets.zero? and parens.zero? and squares.zero?
                break if ['"', "'", ',', ';', '%'].include?(char)
                signature = char + signature if char.match(/[a-z0-9:\._@\$\?\!]/i) and @source.code[index - 1] != '%'
                break if char == '$'
                if char == '@'
                  signature = "@#{signature}" if @source.code[index-1, 1] == '@'
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
          pos = Position.from_offset(@source.code, index)
          node = @source.node_at(pos.line, pos.character)
          lit = infer_literal_node_type(node)
          unless lit.nil?
            signature = signature[1..-1].to_s
            index += 1
            @base_literal = lit
          end
        end
        [index + 1, signature]
      end

      # @return [String]
      def remainder_at index
        cursor = index
        while cursor < @source.code.length
          char = @source.code[cursor, 1]
          break if char.nil? or char == ''
          break unless char.match(/[a-z0-9_\?\!]/i)
          cursor += 1
        end
        @source.code[index..cursor-1].to_s
      end
    end
  end
end
