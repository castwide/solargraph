require 'parser/current'

module Solargraph
  # A Ruby file that has been parsed into an AST.
  #
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

    # @return [Array<Parser::Source::Comment>]
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
      @repaired = code
      @filename = filename
      @version = version
      @domains = []
      begin
        @node, @comments = Source.parse_with_comments(@code, filename)
        @parsed = true
      rescue Parser::SyntaxError, EncodingError => e
        # @todo 100% whitespace results in a nil node, so there's no reason to parse it.
        #   We still need to determine whether the resulting node should be nil or a dummy
        #   node with a location that encompasses the range.
        # @node, @comments = Source.parse_with_comments(@code.gsub(/[^\s]/, ' '), filename)
        @node = nil
        @comments = []
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

    # @return [Array<Range>]
    def error_ranges
      @error_ranges ||= []
    end

    def code_for(node)
      # @todo Using node locations on code with converted EOLs seems
      #   slightly more efficient than calculating offsets.
      # b = node.location.expression.begin.begin_pos
      # e = node.location.expression.end.end_pos
      b = Position.line_char_to_offset(@code, node.location.line, node.location.column)
      e = Position.line_char_to_offset(@code, node.location.last_line, node.location.last_column)
      frag = code[b..e-1].to_s
      frag.strip.gsub(/,$/, '')
    end

    # @param node [Parser::AST::Node]
    # @return [String]
    def comments_for node
      arr = associated_comments[node.loc.line]
      arr ? stringify_comment_array(arr) : nil
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

    private

    # Get a hash of comments grouped by the line numbers of the associated code.
    #
    # @return [Hash{Integer => Array<Parser::Source::Comment>}]
    def associated_comments
      @associated_comments ||= begin
        result = {}
        Parser::Source::Comment.associate_locations(node, comments).each_pair do |loc, all|
          block = all.select{ |l| l.document? || code.lines[l.loc.line].strip.start_with?('#')}
          next if block.empty?
          result[loc.line] ||= []
          result[loc.line].concat block
        end
        result
      end
    end

    # Get a string representation of an array of comments.
    #
    # @param comments [Array<Parser::Source::Comment>]
    # @return [String]
    def stringify_comment_array comments
      ctxt = ''
      num = nil
      started = false
      comments.each { |l|
        # Trim the comment and minimum leading whitespace
        p = l.text.gsub(/^#/, '')
        if num.nil? and !p.strip.empty?
          num = p.index(/[^ ]/)
          started = true
        elsif started and !p.strip.empty?
          cur = p.index(/[^ ]/)
          num = cur if cur < num
        end
        ctxt += "#{p[num..-1]}\n" if started
      }
      ctxt
    end

    # @return [Array<Range>]
    def string_ranges
      @string_ranges ||= string_ranges_in(@node)
    end

    # @return [Array<Range>]
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

    # @return [Integer]
    attr_writer :version

    # @return [String]
    attr_writer :code

    # @return [String]
    attr_accessor :repaired

    # @return [Boolean]
    attr_writer :parsed

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
      # @param version [Integer]
      # @return [Solargraph::Source]
      def load_string code, filename = nil, version = 0
        Source.new code, filename, version
      end

      # @param code [String]
      # @param filename [String]
      # @return [Array(Parser::AST::Node, Array<Parser::Source::Comment>)]
      def parse_with_comments code, filename = nil
        buffer = Parser::Source::Buffer.new(filename, 0)
        buffer.source = code.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '_')
        parser.parse_with_comments(buffer)
      end

      # @param code [String]
      # @param filename [String]
      # @return [Parser::AST::Node]
      def parse code, filename = nil, line = 0
        buffer = Parser::Source::Buffer.new(filename, line)
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
