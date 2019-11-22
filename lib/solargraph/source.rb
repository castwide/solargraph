# frozen_string_literal: true

require 'parser/current'
require 'yard'

module Solargraph
  # A Ruby file that has been parsed into an AST.
  #
  class Source
    # autoload :FlawedBuilder, 'solargraph/source/flawed_builder'
    autoload :Updater,       'solargraph/source/updater'
    autoload :Change,        'solargraph/source/change'
    autoload :Mapper,        'solargraph/source/mapper'
    # autoload :NodeMethods,   'solargraph/source/node_methods'
    autoload :EncodingFixes, 'solargraph/source/encoding_fixes'
    autoload :Cursor,        'solargraph/source/cursor'
    autoload :Chain,         'solargraph/source/chain'
    autoload :SourceChainer, 'solargraph/source/source_chainer'
    # autoload :NodeChainer,   'solargraph/source/node_chainer'

    include EncodingFixes
    # include NodeMethods

    # @return [String]
    attr_reader :filename

    # @return [String]
    attr_reader :code

    # @return [Parser::AST::Node]
    attr_reader :node

    # @return [Hash{Integer => Array<String>}]
    attr_reader :comments

    # @todo Deprecate?
    # @return [Integer]
    attr_reader :version

    # @param code [String]
    # @param filename [String]
    # @param version [Integer]
    def initialize code, filename = nil, version = 0
      @code = normalize(code)
      @repaired = code
      @filename = filename
      @version = version
      @domains = []
      begin
        # @node, @comments = Source.parse_with_comments(@code, filename)
        @node, @comments = Solargraph::Parser.parse_with_comments(@code, filename)
        @parsed = true
      rescue Parser::SyntaxError, EncodingError => e
        # @todo 100% whitespace results in a nil node, so there's no reason to parse it.
        #   We still need to determine whether the resulting node should be nil or a dummy
        #   node with a location that encompasses the range.
        # @node, @comments = Source.parse_with_comments(@code.gsub(/[^\s]/, ' '), filename)
        @node = nil
        @comments = {}
        @parsed = false
      # rescue Exception => e
      #   Solargraph.logger.warn "[#{e.class}] #{e.message}"
      #   Solargraph.logger.warn e.backtrace.join("\n")
      #   raise "Error parsing #{filename || '(source)'}: [#{e.class}] #{e.message}"
      ensure
        @code.freeze
      end
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
      b = Solargraph::Position.line_char_to_offset(@code, l1, c1)
      e = Solargraph::Position.line_char_to_offset(@code, l2, c2)
      @code[b..e-1]
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
      # offset = Position.line_char_to_offset(@code, line, column)
      position = Position.new(line, column)
      stack = []
      inner_tree_at @node, position, stack
      stack
    end

    # Start synchronizing the source. This method updates the code without
    # parsing a new AST. The resulting Source object will be marked not
    # synchronized (#synchronized? == false).
    #
    # @param updater [Source::Updater]
    # @return [Source]
    def start_synchronize updater
      raise 'Invalid synchronization' unless updater.filename == filename
      real_code = updater.write(@code)
      src = Source.allocate
      src.filename = filename
      src.code = real_code
      src.version = updater.version
      src.parsed = parsed?
      src.repaired = updater.repair(@repaired)
      src.synchronized = false
      src.node = @node
      src.comments = @comments
      src.error_ranges = error_ranges
      src.last_updater = updater
      return src.finish_synchronize unless real_code.lines.length == @code.lines.length
      src
    end

    # Finish synchronizing a source that was updated via #start_synchronize.
    # This method returns self if the source is already synchronized. Otherwise
    # it parses the AST and returns a new synchronized Source.
    #
    # @return [Source]
    def finish_synchronize
      return self if synchronized?
      synced = Source.new(@code, filename)
      if synced.parsed?
        synced.version = version
        return synced
      end
      synced = Source.new(@repaired, filename)
      synced.error_ranges.concat (error_ranges + last_updater.changes.map(&:range))
      synced.code = @code
      synced.synchronized = true
      synced.version = version
      synced
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
      synced = Source.new(real_code, filename)
      if synced.parsed?
        synced.version = updater.version
        return synced
      end
      incr_code = updater.repair(@repaired)
      synced = Source.new(incr_code, filename)
      synced.error_ranges.concat (error_ranges + updater.changes.map(&:range))
      synced.code = real_code
      synced.version = updater.version
      synced
    end

    # @param position [Position]
    # @return [Source::Cursor]
    def cursor_at position
      Cursor.new(self, position)
    end

    # @return [Boolean]
    def parsed?
      @parsed
    end

    def repaired?
      @is_repaired ||= (@code != @repaired)
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
      b = Position.line_char_to_offset(@code, rng.start.line, rng.start.column)
      e = Position.line_char_to_offset(@code, rng.ending.line, rng.ending.column)
      frag = code[b..e-1].to_s
      frag.strip.gsub(/,$/, '')
    end

    # @param node [Parser::AST::Node]
    # @return [String]
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
      @synchronized = true if @synchronized.nil?
      @synchronized
    end

    # Get a hash of comments grouped by the line numbers of the associated code.
    #
    # @return [Hash{Integer => Array<Parser::Source::Comment>}]
    def associated_comments
      @associated_comments ||= begin
        result = {}
        buffer = String.new('')
        last = nil
        @comments.each_pair do |num, snip|
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

    def first_not_empty_from line
      cursor = line
      cursor += 1 while cursor < code.lines.length && code.lines[cursor].strip.empty?
      cursor = line if cursor > code.lines.length
      cursor
    end

    # @param top [Parser::AST::Node]
    # @param result [Array<Range>]
    # @return [void]
    def inner_folding_ranges top, result = []
      return unless top.is_a?(::Parser::AST::Node)
      if FOLDING_NODE_TYPES.include?(top.type)
        range = Range.from_node(top)
        if result.empty? || range.start.line > result.last.start.line
          result.push range unless range.ending.line - range.start.line < 2
        end
      end
      top.children.each do |child|
        inner_folding_ranges(child, result)
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
        p = l.gsub(/^#+/, '')
        next if p.strip.empty? && !started
        here = p.index(/[^ \t]/)
        skip = here if skip.nil? || here < skip
        ctxt.concat p[skip..-1]
        started = true
      }
      ctxt
    end

    # A hash of line numbers and their associated comments.
    #
    # @return [Hash{Integer => Array<String>}]
    def stringified_comments
      @stringified_comments ||= {}
    end

    # @return [Array<Parser::AST::Node>]
    def string_nodes
      @string_nodes ||= string_nodes_in(@node)
    end

    # @return [Array<Range>]
    def comment_ranges
      @comment_ranges ||= @comments.values.map(&:range)
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

    # @param n [Parser::AST::Node]
    # @return [Array<Parser::AST::Node>]
    def string_nodes_in n
      result = []
      if n.is_a?(::Parser::AST::Node)
        if n.type == :str || n.type == :dstr
          result.push n
        else
          n.children.each{ |c| result.concat string_nodes_in(c) }
        end
      end
      result
    end

    # @param node [Parser::AST::Node]
    # @param position [Position]
    # @param stack [Array<Parser::AST::Node>]
    # @return [void]
    def inner_tree_at node, position, stack
      return if node.nil?
      # here = Range.from_to(node.loc.expression.line, node.loc.expression.column, node.loc.expression.last_line, node.loc.expression.last_column)
      here = Range.from_node(node)
      if here.contain?(position)
        stack.unshift node
        node.children.each do |c|
          # next unless c.is_a?(AST::Node)
          next unless Parser.is_ast_node?(c)
          # next if c.loc.expression.nil?
          rng = Range.from_node(c)
          inner_tree_at(c, rng.start, stack)
        end
      end
    end

    protected

    # @return [String]
    attr_writer :filename

    # @return [Integer]
    attr_writer :version

    # @return [String]
    attr_writer :code

    # @return [Parser::AST::Node]
    attr_writer :node

    # @return [Array<Range>]
    attr_writer :error_ranges

    # @return [String]
    attr_accessor :repaired

    # @return [Boolean]
    attr_writer :parsed

    # @return [Array<Parser::Source::Comment>]
    attr_writer :comments

    # @return [Boolean]
    attr_writer :synchronized

    # @return [Source::Updater]
    attr_accessor :last_updater

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
      # @param filename [String]
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
      end
    end
  end
end
