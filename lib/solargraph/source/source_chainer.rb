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
        return Chain.new([Chain::UNDEFINED_CALL]) if phrase.end_with?(':') && !phrase.end_with?('::')
        begin
          node = (source.repaired? || !source.parsed?) ? Source.parse(fixed_phrase) : source.node_at(position.line, position.column)
        rescue Parser::SyntaxError
          return Chain.new([Chain::UNDEFINED_CALL])
        end
        chain = NodeChainer.chain(node, source.filename)
        if source.repaired? || !source.parsed?
          if end_of_phrase.strip == '.'
            chain.links.push Chain::UNDEFINED_CALL
          elsif end_of_phrase.strip == '::'
            chain.links.push Chain::UNDEFINED_CONSTANT
          end
        end
        chain
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

      def phrase
        @phrase ||= source.code[signature_data[0]..offset-1]
      end

      def fixed_phrase
        @fixed_phrase ||= phrase[0..-(end_of_phrase.length+1)]
      end

      def end_of_phrase
        @end_of_phrase ||= begin
          match = phrase.match(/[\s]*(\.{1}|:{1,2})?[\s]*$/)
          if match
            match[0]
          else
            ''
          end
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

      # True if the current offset is inside a string.
      #
      # @return [Boolean]
      def string?
        # @string ||= (node.type == :str or node.type == :dstr)
        @string ||= @source.string_at?(position)
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
    end
  end
end
