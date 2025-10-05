# frozen_string_literal: true

require 'yard'

module Solargraph
  # A Ruby file that has been parsed into an AST.
  #
  class Source
    autoload :Updater,       'solargraph/source/updater'
    autoload :Change,        'solargraph/source/change'
    autoload :EncodingFixes, 'solargraph/source/encoding_fixes'
    autoload :Cursor,        'solargraph/source/cursor'
    autoload :Chain,         'solargraph/source/chain'
    autoload :SourceChainer, 'solargraph/source/source_chainer'

    include EncodingFixes

    # @return [String]
    attr_reader :filename

    # @return [String]
    def code
      finalize
      @code
    end

    # @return [Parser::AST::Node, nil]
    def node
      finalize
      @node
    end

    # @return [Hash{Integer => Solargraph::Parser::Snippet}]
    def comments
      finalize
      @comments
    end

    # @todo Deprecate?
    # @return [Integer]
    attr_reader :version

    # @param code [String]
    # @param filename [String, nil]
    # @param version [Integer]
    def initialize code, filename = nil, version = 0
      @code = normalize(code)
      @repaired = code
      @filename = filename
      @version = version
    end

    # @param range [Solargraph::Range]
    # @return [String]
    def at range
      from_to range.start.line, range.start.character, range.ending.line, range.ending.character
    end

    # @param l1 [Integer]
    # @param c1 [Integer]
    # @param l2 [Integer]
    # @param c2 [Integer]
    # @return [String]
    def from_to l1, c1, l2, c2
      b = Solargraph::Position.line_char_to_offset(code, l1, c1)
      e = Solargraph::Position.line_char_to_offset(code, l2, c2)
      code[b..e-1]
    end

    # Get the nearest node that contains the specified index.
    #
    # @param line [Integer]
    # @param column [Integer]
    # @return [AST::Node]
    def node_at(line, column)
      tree_at(line, column).first
    end

    # Get an array of nodes containing the specified index, starting with the
    # nearest node and ending with the root.
    #
    # @param line [Integer]
    # @param column [Integer]
    # @return [Array<AST::Node>]
    def tree_at(line, column)
      position = Position.new(line, column)
      stack = []
      inner_tree_at node, position, stack
      stack
    end

    # Synchronize the Source with an update. This method applies changes to the
    # code, parses the new code's AST, and returns the resulting Source object.
    #
    # @param updater [Source::Updater]
    # @return [Source]
    def synchronize updater
      raise 'Invalid synchronization' unless updater.filename == filename
      real_code = updater.write(@code)
      if real_code == @code
        @version = updater.version
        return self
      end
      Source.new(@code, filename, updater.version).tap do |src|
        src.repaired = @repaired
        src.error_ranges.concat error_ranges
        src.changes.concat(changes + updater.changes)
      end
    end

    # @param position [Position, Array(Integer, Integer)]
    # @return [Source::Cursor]
    def cursor_at position
      finalize
      Cursor.new(self, position)
    end

    # @return [Boolean]
    def parsed?
      finalize
      @parsed
    end

    def repaired?
      code != @repaired
    end

    # @param position [Position]
    # @return [Boolean]
    def string_at? position
      return false if Position.to_offset(code, position) >= code.length
      string_nodes.each do |node|
        range = Range.from_node(node)
        next if range.ending.line < position.line
        break if range.ending.line > position.line
        return true if node.type == :str && range.include?(position) && range.start != position
        return true if [:STR, :str].include?(node.type) && range.include?(position) && range.start != position
        if node.type == :dstr
          inner = node_at(position.line, position.column)
          next if inner.nil?
          inner_range = Range.from_node(inner)
          next unless range.include?(inner_range.ending)
          return true if inner.type == :str
          inner_code = at(Solargraph::Range.new(inner_range.start, position))
          return true if (inner.type == :dstr && inner_range.ending.character <= position.character) && !inner_code.end_with?('}') ||
                         (inner.type != :dstr && inner_range.ending.line == position.line && position.character <= inner_range.ending.character && inner_code.end_with?('}'))
        end
        break if range.ending.line > position.line
      end
      false
    end

    # @return [::Array<Range>]
    def string_ranges
      @string_ranges ||= Parser.string_ranges(node)
    end

    # @param position [Position]
    # @return [Boolean]
    def comment_at? position
      comment_ranges.each do |range|
        return true if range.include?(position) ||
          (range.ending.line == position.line && range.ending.column < position.column)
        break if range.ending.line > position.line
      end
      false
    end

    # @param name [String]
    # @return [Array<Location>]
    def references name
      Parser.references self, name
    end

    # @return [Array<Range>]
    def error_ranges
      @error_ranges ||= []
    end

    # @param node [Parser::AST::Node]
    # @return [String]
    def code_for(node)
      rng = Range.from_node(node)
      b = Position.line_char_to_offset(code, rng.start.line, rng.start.column)
      e = Position.line_char_to_offset(code, rng.ending.line, rng.ending.column)
      frag = code[b..e-1].to_s
      frag.strip.gsub(/,$/, '')
    end

    # @param node [AST::Node]
    # @return [String, nil]
    def comments_for node
      rng = Range.from_node(node)
      stringified_comments[rng.start.line] ||= begin
        buff = associated_comments[rng.start.line]
        buff ? stringify_comment_array(buff) : nil
      end
    end

    # A location representing the file in its entirety.
    #
    # @return [Location]
    def location
      st = Position.new(0, 0)
      en = Position.from_offset(code, code.length)
      range = Range.new(st, en)
      Location.new(filename, range)
    end

    FOLDING_NODE_TYPES = %i[
        class sclass module def defs if str dstr array while unless kwbegin hash block
      ].freeze

    # Get an array of ranges that can be folded, e.g., the range of a class
    # definition or an if condition.
    #
    # See FOLDING_NODE_TYPES for the list of node types that can be folded.
    #
    # @return [Array<Range>]
    def folding_ranges
      @folding_ranges ||= begin
        result = []
        inner_folding_ranges node, result
        result.concat foldable_comment_block_ranges
        result
      end
    end

    def synchronized?
      true
    end

    # Get a hash of comments grouped by the line numbers of the associated code.
    #
    # @return [Hash{Integer => String}]
    def associated_comments
      @associated_comments ||= begin
        # @type [Hash{Integer => String}]
        result = {}
        buffer = String.new('')
        # @type [Integer, nil]
        last = nil
        comments.each_pair do |num, snip|
          if !last || num == last + 1
            buffer.concat "#{snip.text}\n"
          else
            result[first_not_empty_from(last + 1)] = buffer.clone
            buffer.replace "#{snip.text}\n"
          end
          last = num
        end
        result[first_not_empty_from(last + 1)] = buffer unless buffer.empty? || last.nil?
        result
      end
    end

    private

    # @param line [Integer]
    # @return [Integer]
    def first_not_empty_from line
      cursor = line
      cursor += 1 while cursor < code_lines.length && code_lines[cursor].strip.empty?
      cursor = line if cursor > code_lines.length - 1
      cursor
    end

    # @param top [Parser::AST::Node]
    # @param result [Array<Range>]
    # @param parent [Symbol, nil]
    # @return [void]
    def inner_folding_ranges top, result = [], parent = nil
      return unless Parser.is_ast_node?(top)
      if FOLDING_NODE_TYPES.include?(top.type)
        range = Range.from_node(top)
        if result.empty? || range.start.line > result.last.start.line
          result.push range unless range.ending.line - range.start.line < 2
        end
      end
      top.children.each do |child|
        inner_folding_ranges(child, result, top.type)
      end
    end

    # Get a string representation of an array of comments.
    #
    # @param comments [String]
    # @return [String]
    def stringify_comment_array comments
      ctxt = String.new('')
      started = false
      skip = nil
      comments.lines.each { |l|
        # Trim the comment and minimum leading whitespace
        p = l.force_encoding('UTF-8').encode('UTF-8', invalid: :replace, replace: '?').gsub(/^#+/, '')
        if p.strip.empty?
          next unless started
          ctxt.concat p
        else
          here = p.index(/[^ \t]/)
          skip = here if skip.nil? || here < skip
          ctxt.concat p[skip..-1]
        end
        started = true
      }
      ctxt
    end

    # A hash of line numbers and their associated comments.
    #
    # @return [Hash{Integer => Array<String>, nil}]
    def stringified_comments
      @stringified_comments ||= {}
    end

    # @return [Array<Parser::AST::Node>]
    def string_nodes
      @string_nodes ||= string_nodes_in(node)
    end

    # @return [Array<Solargraph::Range>]
    def comment_ranges
      @comment_ranges ||= comments.values.map(&:range)
    end

    # Get an array of foldable comment block ranges. Blocks are excluded if
    # they are less than 3 lines long.
    #
    # @return [Array<Range>]
    def foldable_comment_block_ranges
      return [] unless synchronized?
      result = []
      grouped = []
      comments.keys.each do |l|
        if grouped.empty? || l == grouped.last + 1
          grouped.push l
        else
          result.push Range.from_to(grouped.first, 0, grouped.last, 0) unless grouped.length < 3
          grouped = [l]
        end
      end
      result.push Range.from_to(grouped.first, 0, grouped.last, 0) unless grouped.length < 3
      result
    end

    # @param n [Parser::AST::Node, nil]
    # @return [Array<Parser::AST::Node>]
    def string_nodes_in n
      result = []
      if Parser.is_ast_node?(n)
        if n.type == :str || n.type == :dstr || n.type == :STR || n.type == :DSTR
          result.push n
        else
          n.children.each{ |c| result.concat string_nodes_in(c) }
        end
      end
      result
    end

    # @param node [Parser::AST::Node, nil]
    # @param position [Position]
    # @param stack [Array<Parser::AST::Node>]
    # @return [void]
    def inner_tree_at node, position, stack
      return if node.nil?
      here = Range.from_node(node)
      if here.contain?(position)
        stack.unshift node
        node.children.each do |c|
          next unless Parser.is_ast_node?(c)
          next if c.loc.expression.nil?
          inner_tree_at(c, position, stack)
        end
      end
    end

    protected

    # @return [Array<Change>]
    def changes
      @changes ||= []
    end

    # @return [String]
    attr_writer :filename

    # @return [Integer]
    attr_writer :version

    # @return [void]
    def finalize
      return if @finalized && changes.empty?

      changes.each do |change|
        @code = change.write(@code)
      end
      @finalized = true
      begin
        @node, @comments = Solargraph::Parser.parse_with_comments(@code, filename)
        @parsed = true
        @repaired = @code
      rescue Parser::SyntaxError, EncodingError => e
        @node = nil
        @comments = {}
        @parsed = false
      ensure
        @code.freeze
      end
      if !@parsed && !changes.empty?
        changes.each do |change|
          @repaired = change.repair(@repaired)
        end
        error_ranges.concat(changes.map(&:range))
        begin
          @node, @comments = Solargraph::Parser.parse_with_comments(@repaired, filename)
          @parsed = true
        rescue Parser::SyntaxError, EncodingError => e
          @node = nil
          @comments = {}
          @parsed = false
        end
      elsif @parsed
        error_ranges.clear
      end
      changes.clear
    end

    # @param val [String]
    # @return [String]
    def code=(val)
      @code_lines = nil
      @finalized = false
      @code = val
    end

    # @return [Parser::AST::Node, nil]
    attr_writer :node

    # @return [Array<Range>]
    attr_writer :error_ranges

    # @return [String]
    attr_writer :repaired

    # @return [String]
    def repaired
      finalize
      @repaired
    end

    # @return [Boolean]
    attr_writer :parsed

    # @return [Hash{Integer => String}
    attr_writer :comments

    # @return [Boolean]
    attr_writer :synchronized

    private

    # @return [Array<String>]
    def code_lines
      @code_lines ||= code.lines
    end

    class << self
      # @param filename [String]
      # @return [Solargraph::Source]
      def load filename
        file = File.open(filename)
        code = file.read
        file.close
        Source.load_string(code, filename)
      end

      # @param code [String]
      # @param filename [String, nil]
      # @param version [Integer]
      # @return [Solargraph::Source]
      def load_string code, filename = nil, version = 0
        Source.new code, filename, version
      end

      # @param comments [String]
      # @return [YARD::DocstringParser]
      def parse_docstring comments
        # HACK: Pass a dummy code object to the parser for plugins that
        # expect it not to be nil
        YARD::Docstring.parser.parse(comments, YARD::CodeObjects::Base.new(:root, 'stub'))
      rescue StandardError => e
        Solargraph.logger.info "YARD failed to parse docstring: [#{e.class}] #{e.message}"
        Solargraph.logger.debug "Unparsed comment: #{comments}"
        YARD::Docstring.parser
      end
    end
  end
end
