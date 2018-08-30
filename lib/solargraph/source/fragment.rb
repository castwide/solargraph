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
        @string ||= @source.string_at?(line, character)
      end

      # True if the current offset is inside a comment.
      #
      # @return [Boolean]
      def comment?
        @comment ||= @source.comment_at?(line, column)
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

      # Get a set of available completions for the specified fragment. The
      # resulting Completion object contains an array of pins and the range of
      # text to replace in the source.
      #
      # @param api_map [ApiMap]
      # @return [Completion]
      def complete api_map
        return Completion.new([], whole_word_range) if chain.literal? or comment?
        result = []
        type = infer_base_type(api_map)
        if chain.tail.constant?
          result.concat api_map.get_constants(type.namespace, namespace)
        else
          result.concat api_map.get_complex_type_methods(type, namespace)
          if chain.links.length == 1
            if word.start_with?('@@')
              return package_completions(api_map.get_class_variable_pins(namespace))
            elsif word.start_with?('@')
              return package_completions(api_map.get_instance_variable_pins(namespace, scope))
            elsif word.start_with?('$')
              return package_completions(api_map.get_global_variable_pins)
            elsif word.start_with?(':') and !word.start_with?('::')
              return package_completions(api_map.get_symbols)
            end
            result.concat api_map.get_constants('', namespace)
            result.concat prefer_non_nil_variables(locals)
            result.concat api_map.get_methods(namespace, scope: scope, visibility: [:public, :private, :protected])
            result.concat api_map.get_methods('Kernel')
            result.concat ApiMap.keywords
          end
        end
        package_completions(result)
      end

      def define api_map
        return [] if chain.literal?
        return [] if string? or comment? or literal?
        # HACK: Checking for self first because it's also a keyword
        return [] if ApiMap::KEYWORDS.include?(chain.links.first.word) and chain.links.first.word != 'self'
        chain.define_with(api_map, named_path, locals)
      end

      # Get an array of pins that describe the method being called by the
      # argument list where the fragment is located. This is useful for queries
      # that need to know what parameters the current method expects to receive.
      #
      # If the fragment is not inside an argument list, return an empty array.
      #
      # @param api_map [Solargraph::Source::Fragment]
      # @return [Array<Solargraph::Pin::Base>]
      def signify api_map
        return [] unless argument?
        return [] if recipient.whole_signature.nil? or recipient.whole_signature.empty?
        result = []
        result.concat recipient.define(api_map)
        result.select{ |pin| pin.kind == Pin::METHOD }
      end

      # @param api_map [ApiMap]
      # @return [ComplexType]
      def infer_base_type api_map
        chain.infer_base_type_with(api_map, named_path, locals)
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

      def generate_chain
        CallChainer.chain(source, line, column)
      end

      def start_word_pattern
        /(@{1,2}|\$)?([a-z0-9_]|[^\u0000-\u007F])*\z/i
      end

      def end_word_pattern
        /^([a-z0-9_]|[^\u0000-\u007F])*[\?\!]?/i
      end

      # @param fragment [Source::Fragment]
      # @param result [Array<Pin::Base>]
      # @return [Completion]
      def package_completions result
        frag_start = word.to_s.downcase
        filtered = result.uniq(&:identifier).select{|s| s.name.downcase.start_with?(frag_start) and (s.kind != Pin::METHOD or s.name.match(/^[a-z0-9_]+(\!|\?|=)?$/i))}.sort_by.with_index{ |x, idx| [x.name, idx] }
        Completion.new(filtered, whole_word_range)
      end

      # Sort an array of pins to put nil or undefined variables last.
      #
      # @param pins [Array<Solargraph::Pin::Base>]
      # @return [Array<Solargraph::Pin::Base>]
      def prefer_non_nil_variables pins
        result = []
        nil_pins = []
        pins.each do |pin|
          if pin.variable? and pin.nil_assignment?
            nil_pins.push pin
          else
            result.push pin
          end
        end
        result + nil_pins
      end
    end
  end
end
