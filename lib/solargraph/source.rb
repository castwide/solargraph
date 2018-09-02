require 'parser/current'
require 'time'

module Solargraph
  class Source
    autoload :FlawedBuilder, 'solargraph/source/flawed_builder'
    # autoload :Position,      'solargraph/source/position'
    # autoload :Range,         'solargraph/source/range'
    autoload :Location,      'solargraph/source/location'
    autoload :Updater,       'solargraph/source/updater'
    autoload :Change,        'solargraph/source/change'
    autoload :Mapper,        'solargraph/source/mapper'
    autoload :NodeMethods,   'solargraph/source/node_methods'
    autoload :EncodingFixes, 'solargraph/source/encoding_fixes'

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
    attr_accessor :version

    # @param code [String]
    # @param filename [String]
    def initialize code, filename = nil
      begin
        @code = normalize(code)
        @fixed = @code
        @filename = filename
        @version = 0
        @domains = []
        parse
      rescue Parser::SyntaxError, EncodingError => e
        hard_fix_node
      rescue Exception => e
        STDERR.puts e.message
        STDERR.puts e.backtrace
        raise "Error parsing #{filename || '(source)'}: [#{e.class}] #{e.message}"
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
    # @return [void]
    def synchronize updater
      raise 'Invalid synchronization' unless updater.filename == filename
      original_code = @code
      original_fixed = @fixed
      @code = updater.write(original_code)
      @fixed = updater.write(original_code, true)
      @version = updater.version
      return if @code == original_code
      begin
        parse
        @fixed = @code
      rescue Parser::SyntaxError, EncodingError => e
        @fixed = updater.repair(original_fixed)
        if @fixed.strip.empty?
          @parsed = false
        else
          begin
            parse
          rescue Parser::SyntaxError, EncodingError => e
            hard_fix_node
          end
        end
      end
    end

    # @return [Boolean]
    def parsed?
      @parsed
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

    # @return [void]
    def parse
      node, comments = inner_parse(@fixed, filename)
      @node = node
      @comments = comments
      @parsed = true
    end

    def hard_fix_node
      @fixed = @code.gsub(/[^\s]/, '_')
      node, comments = inner_parse(@fixed, filename)
      @node = node
      @comments = comments
      @parsed = false
    end

    def inner_parse code, filename
      parser = Parser::CurrentRuby.new(FlawedBuilder.new)
      parser.diagnostics.all_errors_are_fatal = true
      parser.diagnostics.ignore_warnings      = true
      buffer = Parser::Source::Buffer.new(filename, 0)
      buffer.source = code.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '_')
      parser.parse_with_comments(buffer)
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
      def load_string code, filename = nil
        Source.new code, filename
      end

      # @todo Deprecate?
      def parse_node code, filename
        parser = Parser::CurrentRuby.new(FlawedBuilder.new)
        parser.diagnostics.all_errors_are_fatal = true
        parser.diagnostics.ignore_warnings      = true
        buffer = Parser::Source::Buffer.new(nil, 0)
        buffer.source = code.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '_')
        parser.parse(buffer)
      end
    end
  end
end
