require 'parser/current'
require 'time'

module Solargraph
  class Source
    autoload :FlawedBuilder, 'solargraph/source/flawed_builder'
    autoload :Fragment,      'solargraph/source/fragment'
    autoload :Position,      'solargraph/source/position'
    autoload :Range,         'solargraph/source/range'
    autoload :Location,      'solargraph/source/location'
    autoload :Updater,       'solargraph/source/updater'
    autoload :Change,        'solargraph/source/change'
    autoload :Mapper,        'solargraph/source/mapper'
    autoload :NodeMethods,   'solargraph/source/node_methods'

    # @return [String]
    attr_reader :code

    # @return [Parser::AST::Node]
    attr_reader :node

    # @return [Array]
    attr_reader :comments

    # @return [String]
    attr_reader :filename

    # Get the file's modification time.
    #
    # @return [Time]
    attr_reader :mtime

    attr_reader :directives

    attr_reader :path_macros

    attr_accessor :version

    # Get the time of the last synchronization.
    #
    # @return [Time]
    attr_reader :stime

    # @return [Array<Solargraph::Pin::Base>]
    attr_reader :pins

    attr_reader :requires

    attr_reader :domains

    attr_reader :locals

    include NodeMethods

    def initialize code, filename = nil
      @code = code
      @fixed = code
      @filename = filename
      # @stubbed_lines = stubbed_lines
      @version = 0
      begin
        parse
      rescue Parser::SyntaxError, EncodingError
        hard_fix_node
      end
    end

    def macro path
      @path_macros[path]
    end

    # @todo Temporary blank
    def path_macros
      @path_macros ||= {}
    end

    # @todo Name problem
    def required
      requires
    end

    # @return [Array<String>]
    def namespaces
      @namespaces ||= pins.select{|pin| pin.kind == Pin::NAMESPACE}.map(&:path)
    end

    # @param fqns [String] The namespace (nil for all)
    # @return [Array<Solargraph::Pin::Namespace>]
    def namespace_pins fqns = nil
      pins.select{|pin| pin.kind == Pin::NAMESPACE}
    end

    # @param fqns [String] The namespace (nil for all)
    # @return [Array<Solargraph::Pin::Method>]
    def method_pins fqns = nil
      pins.select{|pin| pin.kind == Solargraph::Pin::METHOD or pin.kind == Solargraph::Pin::ATTRIBUTE}
    end

    # @return [Array<Solargraph::Pin::Attribute>]
    def attribute_pins
      pins.select{|pin| pin.kind == Pin::ATTRIBUTE}
    end

    # @return [Array<Solargraph::Pin::InstanceVariable>]
    def instance_variable_pins
      pins.select{|pin| pin.kind == Pin::INSTANCE_VARIABLE}
    end

    # @return [Array<Solargraph::Pin::ClassVariable>]
    def class_variable_pins
      pins.select{|pin| pin.kind == Pin::CLASS_VARIABLE}
    end

    def locals
      @locals
    end

    # @return [Array<Solargraph::Pin::GlobalVariable>]
    def global_variable_pins
      pins.select{|pin| pin.kind == Pin::GLOBAL_VARIABLE}
    end

    # @return [Array<Solargraph::Pin::Constant>]
    def constant_pins
      pins.select{|pin| pin.kind == Pin::CONSTANT}
    end

    # @return [Array<Solargraph::Pin::Symbol>]
    def symbol_pins
      @symbols
    end

    def symbols
      symbol_pins
    end

    # @return [Array<Source::Location>]
    def references name
      inner_node_references(name, node).map do |n|
        offset = Position.to_offset(code, get_node_start_position(n))
        soff = code.index(name, offset)
        eoff = soff + name.length
        Location.new(
          filename,
          Solargraph::Source::Range.new(
            Position.from_offset(code, soff),
            Position.from_offset(code, eoff)
          )
        )
      end
    end

    def locate_named_path_pin line, character
      _locate_pin line, character, Pin::NAMESPACE, Pin::METHOD
    end

    def locate_namespace_pin line, character
      _locate_pin line, character, Pin::NAMESPACE
    end

    def locate_block_pin line, character
      _locate_pin line, character, Pin::NAMESPACE, Pin::METHOD, Pin::BLOCK
    end

    def _locate_pin line, character, *kinds
      position = Solargraph::Source::Position.new(line, character)
      found = nil
      pins.each do |pin|
        found = pin if (kinds.empty? or kinds.include?(pin.kind)) and pin.location.range.contain?(position)
        break if pin.location.range.start.line > line
      end
      # @todo Assuming the root pin is always valid
      found || pins.first
    end

    # Get the nearest node that contains the specified index.
    #
    # @param line [Integer]
    # @param column [Integer]
    # @return [AST::Node]
    def node_at(line, column)
      tree_at(line, column).first
    end

    def string_at?(line, column)
      node = node_at(line, column)
      # @todo raise InvalidOffset or InvalidRange or something?
      return false if node.nil?
      node.type == :str or node.type == :dstr
    end

    # Get an array of nodes containing the specified index, starting with the
    # nearest node and ending with the root.
    #
    # @param index [Integer]
    # @return [Array<AST::Node>]
    def tree_at(line, column)
      offset = Position.line_char_to_offset(@code, line, column)
      stack = []
      inner_tree_at @node, offset, stack
      stack
    end

    def inner_tree_at node, offset, stack
      return if node.nil?
      stack.unshift node
      node.children.each do |c|
        next unless c.is_a?(AST::Node)
        next if c.loc.expression.nil?
        if offset >= c.loc.expression.begin_pos and offset < c.loc.expression.end_pos
          inner_tree_at(c, offset, stack)
          break
        end
      end
    end

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
        begin
          parse
        rescue Parser::SyntaxError, EncodingError => e
          hard_fix_node
        end
      end
    end

    def query_symbols query
      return [] if query.empty?
      down = query.downcase
      all_symbols.select{|p| p.path.downcase.include?(down)}
    end

    def all_symbols
      result = []
      result.concat namespace_pins.reject{ |pin| pin.name.empty? }
      result.concat method_pins
      result.concat constant_pins
      result
    end

    def locate_pin location
      return nil unless location.start_with?("#{filename}:")
      @all_pins.select{|pin| pin.location == location}.first
    end

    # @return [Solargraph::Source::Fragment]
    def fragment_at line, column
      Fragment.new(self, line, column)
    end

    def parsed?
      @parsed
    end

    private

    def inner_node_references name, top
      result = []
      if top.kind_of?(AST::Node)
        if (top.type == :const and top.children[1].to_s == name) or (top.type == :send and top.children[1].to_s == name)
          result.push top
        end
        top.children.each { |c| result.concat inner_node_references(name, c) }
      end
      result
    end

    def parse
      node, comments = inner_parse(@fixed, filename)
      @node = node
      @comments = comments
      process_parsed node, comments
      @parsed = true
    end

    def hard_fix_node
      @fixed = @code.gsub(/[^\s]/, '_')
      node, comments = inner_parse(@fixed, filename)
      @node = node
      @comments = comments
      process_parsed node, comments
      @parsed = false
    end

    def inner_parse code, filename
      parser = Parser::CurrentRuby.new(FlawedBuilder.new)
      parser.diagnostics.all_errors_are_fatal = true
      parser.diagnostics.ignore_warnings      = true
      buffer = Parser::Source::Buffer.new(filename, 1)
      buffer.source = code.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ' ')
      parser.parse_with_comments(buffer)
    end

    def process_parsed node, comments
      @pins, @locals, @requires, @symbols, @path_macros, @domains = Mapper.map filename, code, node, comments
      @stime = Time.now
    end

    class << self
      # @return [Solargraph::Source]
      def load filename
        code = File.read(filename)
        Source.load_string(code, filename)
      end

      # @return [Solargraph::Source]
      def load_string code, filename = nil
        Source.new code, filename
      end
    end
  end
end
