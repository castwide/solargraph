require 'parser/current'
require 'time'

module Solargraph
  class Source
    autoload :FlawedBuilder, 'solargraph/source/flawed_builder'
    autoload :Updater,       'solargraph/source/updater'
    autoload :Change,        'solargraph/source/change'
    autoload :Mapper,        'solargraph/source/mapper'
    autoload :NodeMethods,   'solargraph/source/node_methods'
    autoload :EncodingFixes, 'solargraph/source/encoding_fixes'
    autoload :Cursor,        'solargraph/source/cursor'
    autoload :Chain,         'solargraph/source/chain'
    autoload :SourceChainer, 'solargraph/source/source_chainer'
    autoload :NodeChainer,   'solargraph/source/node_chainer'

    include EncodingFixes
    include NodeMethods

    # @return [String]
    attr_reader :code

    # @return [Parser::AST::Node]
    attr_reader :node

    attr_reader :comments

    # @return [String]
    attr_reader :filename

    # @todo Deprecate?
    # @return [Integer]
    attr_reader :version

    # @param code [String]
    # @param filename [String]
    # @param version [Integer]
    def initialize code, filename = nil, version = 0
      @code = normalize(code)
      @filename = filename
      @version = version
      @domains = []
      begin
        @node, @comments = Source.parse_with_comments(@code, filename)
        @parsed = true
      rescue Parser::SyntaxError, EncodingError => e
        @node, @comments = Source.parse_with_comments(@code.gsub(/[^s]/, '_'), filename)
        @parsed = false
      rescue Exception => e
        STDERR.puts e.message
        STDERR.puts e.backtrace
        raise "Error parsing #{filename || '(source)'}: [#{e.class}] #{e.message}"
      ensure
        @code.freeze
      end
    end

    # @param range [Solargraph::Range]
    def at range
      from_to range.start.line, range.start.character, range.ending.line, range.ending.character
    end

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

    # @param updater [Source::Updater]
    # @param reparse [Boolean]
    # @return [Source]
    def synchronize updater
      raise 'Invalid synchronization' unless updater.filename == filename
      new_code = updater.write(@code)
      if new_code == @code
        @version = updater.version
        return self
      end
      repaired = updater.write(@code, true)
      synced = Source.new(repaired, filename)
      synced.code = new_code
      synced.version = updater.version
      synced
    end

    def cursor_at position
      Cursor.new(self, position)
    end

    # @return [Boolean]
    def parsed?
      @parsed
    end

    # @param position [Position]
    # @return [Boolean]
    def string_at? position
      string_ranges.each do |range|
        return true if range.include?(position)
        break if range.ending.line > position.line
      end
      false
    end

    # @param position [Position]
    # @return [Boolean]
    def comment_at? position
      comment_ranges.each do |range|
        return true if range.include?(position)
        break if range.ending.line > position.line
      end
      false
    end

    # @param name [String]
    # @return [Array<Location>]
    def references name
      inner_node_references(name, node).map do |n|
        offset = Position.to_offset(code, get_node_start_position(n))
        soff = code.index(name, offset)
        eoff = soff + name.length
        Location.new(
          filename,
          Range.new(
            Position.from_offset(code, soff),
            Position.from_offset(code, eoff)
          )
        )
      end
    end

    private

    def string_ranges
      @string_ranges ||= string_ranges_in(@node)
    end

    def comment_ranges
      @comment_ranges || @comments.map do |cmnt|
        Range.from_expr(cmnt.loc.expression)
      end
    end

    def string_ranges_in n
      result = []
      if n.is_a?(Parser::AST::Node)
        if n.type == :str
          result.push Range.from_node(n)
        else
          n.children.each{ |c| result.concat string_ranges_in(c) }
        end
      end
      result
    end

    def inner_tree_at node, position, stack
      return if node.nil?
      here = Range.from_to(node.loc.expression.line, node.loc.expression.column, node.loc.expression.last_line, node.loc.expression.last_column)
      if here.contain?(position)
        stack.unshift node
        node.children.each do |c|
          next unless c.is_a?(AST::Node)
          next if c.loc.expression.nil?
          inner_tree_at(c, position, stack)
        end
      end
    end

    def inner_node_references name, top
      result = []
      if top.kind_of?(AST::Node)
        if top.children.any?{|c| c.to_s == name}
          result.push top
        end
        top.children.each { |c| result.concat inner_node_references(name, c) }
      end
      result
    end

    protected

    attr_writer :version

    attr_writer :code

    class << self
      # @param filename [String]
      # @return [Solargraph::Source]
      def load filename
        file = File.open(filename, 'rb')
        code = file.read
        file.close
        Source.load_string(code, filename)
      end

      # @param code [String]
      # @param filename [String]
      # @return [Solargraph::Source]
      def load_string code, filename = nil, version = 0
        Source.new code, filename, version
      end

      def parse_with_comments code, filename = nil
        buffer = Parser::Source::Buffer.new(filename, 0)
        buffer.source = code.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '_')
        parser.parse_with_comments(buffer)
      end

      def parse code, filename = nil
        buffer = Parser::Source::Buffer.new(filename, 0)
        buffer.source = code.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '_')
        parser.parse(buffer)
      end

      private

      # @return [Parser::Base]
      def parser
        # @todo Consider setting an instance variable. We might not need to
        #   recreate the parser every time we use it.
        parser = Parser::CurrentRuby.new(FlawedBuilder.new)
        parser.diagnostics.all_errors_are_fatal = true
        parser.diagnostics.ignore_warnings      = true
        parser
      end
    end
  end
end
