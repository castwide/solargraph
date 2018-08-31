module Solargraph
  class Source
    # Information about a position in a source, including the word containing
    # that position and the current context.
    #
    class Fragment
      include NodeMethods

      # @return [Source]
      attr_reader :source

      # @return [Position]
      attr_reader :position

      # @param source [Source]
      # @param position [Position, Array(Integer, Integer)]
      def initialize source, position
        @source = source
        @position = if position.is_a?(Array)
                      Position.new(position[0], position[1])
                    else
                      position
                    end
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

      # The range of the word at the current position.
      #
      # @return [Range]
      def range
        @range ||= begin
          s = Position.from_offset(source.code, offset - start_of_word.length)
          e = Position.from_offset(source.code, offset + end_of_word.length)
          Solargraph::Source::Range.new(s, e)
        end
      end

      # The context at the current position.
      #
      # @return [Context]
      def context
        @context ||= source.locate_named_path_pin(position.line, position.character).context
      end

      # The chain at the current position.
      #
      # @return [Chain]
      def chain
        @chain ||= CallChainer.chain(source, position.line, position.column)
      end

      # Get an array of all the locals that are visible from the fragment's
      # position. Locals can be local variables, method parameters, or block
      # parameters. The array starts with the nearest local pin.
      #
      # @return [Array<Solargraph::Pin::Base>]
      def locals
        @locals ||= source.locals.select { |pin|
          pin.visible_from?(block, position)
        }.reverse
      end

      def argument?
        @argument ||= !signature_position.nil?
      end

      def recipient
        return nil unless argument?
        @recipient ||= source.fragment_at(signature_position.line, signature_position.column)
      end

      private

      # @return [Integer]
      def offset
        @offset = Position.to_offset(source.code, position)
      end

      def start_word_pattern
        /(@{1,2}|\$)?([a-z0-9_]|[^\u0000-\u007F])*\z/i
      end

      def end_word_pattern
        /^([a-z0-9_]|[^\u0000-\u007F])*[\?\!]?/i
      end

      # @return [Solargraph::Pin::Base]
      def block
        @block ||= @source.locate_block_pin(position.line, position.character)
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
            @signature_position = Source::Position.from_offset(source.code, cursor)
          end
        end
        @signature_position
      end
    end
  end
end
