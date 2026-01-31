# frozen_string_literal: true

module Solargraph
  class Source
    # Information about a location in a source, including the location's word
    # and signature, literal values at the base of signatures, and whether the
    # location is inside a string or comment. ApiMaps use Fragments to provide
    # results for completion and definition queries.
    #
    class SourceChainer
      # include Source::NodeMethods

      private_class_method :new

      class << self
        # @param source [Source]
        # @param position [Position, Array(Integer, Integer)]
        # @return [Source::Chain]
        def chain source, position
          new(source, Solargraph::Position.normalize(position)).chain
        end
      end

      # @param source [Source]
      # @param position [Position]
      def initialize source, position
        @source = source
        @position = position
        @calculated_literal = false
      end

      # @return [Source::Chain]
      def chain
        # Special handling for files that end with an integer and a period
        if phrase =~ /^[0-9]+\.$/
          return Chain.new([Chain::Literal.new('Integer', Integer(phrase[0..-2])),
                            Chain::UNDEFINED_CALL])
        end
        if phrase.start_with?(':') && !phrase.start_with?('::')
          return Chain.new([Chain::Literal.new('Symbol',
                                               # @sg-ignore Need to add nil check here
                                               phrase[1..].to_sym)])
        end
        if end_of_phrase.strip == '::' && source.code[Position.to_offset(
          source.code, position
        )].to_s.match?(/[a-z]/i)
          return SourceChainer.chain(source,
                                     Position.new(position.line,
                                                  position.character + 1))
        end
        begin
          return Chain.new([]) if phrase.end_with?('..')
          # @type [::Parser::AST::Node, nil]
          node = nil
          # @type [::Parser::AST::Node, nil]
          parent = nil
          if !source.repaired? && source.parsed? && source.synchronized?
            tree = source.tree_at(position.line, position.column)
            node, parent = tree[0..2]
          elsif source.parsed? && source.repaired? && end_of_phrase == '.'
            node, parent = source.tree_at(fixed_position.line, fixed_position.column)[0..2]
            # provide filename and line so that we can look up local variables there later
            node = Parser.parse(fixed_phrase, source.filename, fixed_position.line) if node.nil?
          elsif source.repaired?
            node = Parser.parse(fixed_phrase, source.filename, fixed_position.line)
          else
            unless source.error_ranges.any? do |r|
              r.nil? || r.include?(fixed_position)
            end
              node, parent = source.tree_at(fixed_position.line,
                                            fixed_position.column)[0..2]
            end
            # Exception for positions that chain literal nodes in unsynchronized sources
            node = nil unless source.synchronized? || !Parser.infer_literal_node_type(node).nil?
            node = Parser.parse(fixed_phrase, source.filename, fixed_position.line) if node.nil?
          end
        rescue Parser::SyntaxError
          return Chain.new([Chain::UNDEFINED_CALL])
        end
        return Chain.new([Chain::UNDEFINED_CALL]) if node.nil? || (node.type == :sym && !phrase.start_with?(':'))
        # chain = NodeChainer.chain(node, source.filename, parent && parent.type == :block)
        chain = Parser.chain(node, source.filename, parent)
        if source.repaired? || !source.parsed? || !source.synchronized?
          if end_of_phrase.strip == '.'
            chain.links.push Chain::UNDEFINED_CALL
          elsif end_of_phrase.strip == '::'
            chain.links.push Chain::UNDEFINED_CONSTANT
          end
        elsif chain.links.last.is_a?(Source::Chain::Constant) && end_of_phrase.strip == '::'
          chain.links.push Source::Chain::UNDEFINED_CONSTANT
        end
        chain
      end

      private

      # @return [Position]
      attr_reader :position

      # @return [Solargraph::Source]
      attr_reader :source

      # @sg-ignore Need to add nil check here
      # @return [String]
      def phrase
        @phrase ||= source.code[signature_data..(offset - 1)]
      end

      # @sg-ignore Need to add nil check here
      # @return [String]
      def fixed_phrase
        @fixed_phrase ||= phrase[0..-(end_of_phrase.length + 1)]
      end

      # @return [Position]
      def fixed_position
        @fixed_position ||= Position.from_offset(source.code, offset - end_of_phrase.length)
      end

      # @return [String]
      # @sg-ignore Need to add nil check here
      def end_of_phrase
        @end_of_phrase ||= begin
          match = phrase.match(/\s*(\.{1}|::)\s*$/)
          if match
            match[0]
          else
            ''
          end
        end
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
        @offset ||= get_offset(position.line, position.column)
      end

      # @param line [Integer]
      # @param column [Integer]
      # @return [Integer]
      def get_offset line, column
        Position.line_char_to_offset(@source.code, line, column)
      end

      # @return [Integer]
      def signature_data
        @signature_data ||= get_signature_data_at(offset)
      end

      # @param index [Integer]
      # @return [Integer]
      def get_signature_data_at index
        brackets = 0
        squares = 0
        parens = 0
        index -= 1
        in_whitespace = false
        while index >= 0
          pos = Position.from_offset(@source.code, index)
          break if index.positive? && @source.comment_at?(pos)
          break if brackets.positive? || parens.positive? || squares.positive?
          char = @source.code[index, 1]
          break if char.nil? # @todo Is this the right way to handle this?
          if brackets.zero? && parens.zero? && squares.zero? && [' ', "\r", "\n", "\t"].include?(char)
            in_whitespace = true
          else
            # @sg-ignore Need to add nil check here
            if brackets.zero? && parens.zero? && squares.zero? && in_whitespace && !((char == '.') || @source.code[(index + 1)..].strip.start_with?('.'))
              @source.code[(index + 1)..]
              # @sg-ignore Need to add nil check here
              @source.code[(index + 1)..].lstrip
              # @sg-ignore Need to add nil check here
              index += (@source.code[(index + 1)..].length - @source.code[(index + 1)..].lstrip.length)
              break
            end
            case char
            when ')'
              parens -= 1
            when ']'
              squares -= 1
            when '}'
              brackets -= 1
            when '('
              parens += 1
            when '{'
              brackets += 1
            when '['
              squares += 1
            end
            if brackets.zero? && parens.zero? && squares.zero?
              break if ['"', "'", ',', ';', '%'].include?(char)
              break if ['!', '?'].include?(char) && index < offset - 1
              break if char == '$'
              if char == '@'
                index -= 1
                index -= 1 if @source.code[index, 1] == '@'
                break
              end
            elsif parens == 1 || brackets == 1 || squares == 1
              break
            end
            in_whitespace = false
          end
          index -= 1
        end
        index + 1
      end
    end
  end
end
