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

    # @return [Integer]
    attr_accessor :version

    # Get the time of the last synchronization.
    #
    # @return [Time]
    attr_reader :stime

    # @return [Array<Solargraph::Pin::Base>]
    attr_reader :pins

    # @return [Array<Solargraph::Pin::Reference>]
    attr_reader :requires

    attr_reader :domains

    # @return [Array<Solargraph::Pin::Base>]
    attr_reader :locals

    include NodeMethods

    # @param code [String]
    # @param filename [String]
    def initialize code, filename = nil
      begin
        @code = code
        @fixed = code
        @filename = filename
        @version = 0
        begin
          parse
        rescue Parser::SyntaxError, EncodingError
          hard_fix_node
        end
      rescue Exception => e
        raise RuntimeError, "Error parsing #{filename || '(source)'}: [#{e.class}] #{e.message}"
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
    # @return [Array<Solargraph::Pin::Reference>]
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

    # @return [Array<Solargraph::Pin::Base>]
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

    # @return [Array<Solargraph::Pin::Symbol>]
    def symbols
      symbol_pins
    end

    # @param name [String]
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

    # Get the nearest node that contains the specified index.
    #
    # @param line [Integer]
    # @param column [Integer]
    # @return [AST::Node]
    def node_at(line, column)
      tree_at(line, column).first
    end

    # True if the specified location is inside a string.
    #
    # @param line [Integer]
    # @param column [Integer]
    # @return [Boolean]
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

    # @param updater [Source::Updater]
    # @param reparse [Boolean]
    # @return [void]
    def synchronize updater, reparse = true
      raise 'Invalid synchronization' unless updater.filename == filename
      original_code = @code
      original_fixed = @fixed
      @code = updater.write(original_code)
      @fixed = updater.write(original_code, true)
      @version = updater.version
      return if @code == original_code
      return unless reparse
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

    # @param query [String]
    # @return [Array<Solargraph::Pin::Base>]
    def query_symbols query
      return [] if query.empty?
      down = query.downcase
      all_symbols.select{|p| p.path.downcase.include?(down)}
    end

    # @return [Array<Solargraph::Pin::Base>]
    def all_symbols
      @all_symbols ||= pins.select{ |pin|
        [Pin::ATTRIBUTE, Pin::CONSTANT, Pin::METHOD, Pin::NAMESPACE].include?(pin.kind) and !pin.name.empty?
      }
    end

    # @param location [Solargraph::Source::Location]
    # @return [Solargraph::Pin::Base]
    def locate_pin location
      return nil unless location.start_with?("#{filename}:")
      @all_pins.select{|pin| pin.location == location}.first
    end

    # @param line [Integer] A zero-based line number
    # @param column [Integer] A zero-based column number
    # @return [Solargraph::Source::Fragment]
    def fragment_at line, column
      Fragment.new(self, line, column)
    end

    # @return [Boolean]
    def parsed?
      @parsed
    end

    private

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

    # @return [void]
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
      new_map_data = Mapper.map(filename, code, node, comments)
      synchronize_mapped *new_map_data
    end

    def synchronize_mapped new_pins, new_locals, new_requires, new_symbols, new_path_macros, new_domains
      relocated = try_relocate(new_pins, new_locals)
      unsynced = (
        !relocated or
        # @pins.nil? or
        # @locals.nil? or
        # @pins.first.location.range.ending.line != new_pins.first.location.range.ending.line or
        # @pins[1..-1] != new_pins[1..-1] or
        # @locals != new_locals
        @requires != new_requires or
        @path_macros != new_path_macros or
        @domains != new_domains
      )
      return unless unsynced
      @pins = new_pins
      @locals = new_locals
      @requires = new_requires
      @symbols = new_symbols
      @path_macros = new_path_macros
      @domains = new_domains
      @stime = Time.now
    end

    # @param new_pins [Array<Solargraph::Pin::Base>]
    # @return [Boolean]
    def try_relocate new_pins, new_locals
      return false if @pins.nil? or @locals.nil? or new_pins.length != @pins.length or new_locals.length != @locals.length
      new_pins.each_index do |i|
        return false unless new_pins[i].nearly?(@pins[i])
        @pins[i].instance_variable_set(:@location, new_pins[i].location)
      end
      new_locals.each_index do |i|
        return false unless new_locals[i].nearly?(@locals[i])
        @locals[i].instance_variable_set(:@location, new_locals[i].location)
        if @locals[i].is_a?(Solargraph::Pin::LocalVariable)
          @locals[i].instance_variable_set(:@presence, new_locals[i].presence)
        end
      end
      true
    end

    class << self
      # @param filename [String]
      # @return [Solargraph::Source]
      def load filename
        code = File.read(filename)
        Source.load_string(code, filename)
      end

      # @param code [String]
      # @param filename [String]
      # @return [Solargraph::Source]
      def load_string code, filename = nil
        Source.new code, filename
      end
    end
  end
end
