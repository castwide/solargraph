require 'parser/current'
require 'time'
require 'yard'

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
    autoload :Chain,         'solargraph/source/chain'
    autoload :Encoding,      'solargraph/source/encoding'
    autoload :CallChainer,  'solargraph/source/call_chainer'

    include Encoding

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
        @code = normalize(code)
        @fixed = @code
        @filename = filename
        @version = 0
        @domains = []
        parse
      rescue Parser::SyntaxError, EncodingError => e
        # @todo Improve error handling
        STDERR.puts "HARD FIX: #{e.class} #{e.message}"
        STDERR.puts e.backtrace
        hard_fix_node
      rescue Exception => e
        raise "Error parsing #{filename || '(source)'}: [#{e.class}] #{e.message}"
      end
    end

    def bookmark line, column
      if @bookmark.nil?
        # @type [Source::Fragment]
        @bookmark = fragment_at(line, column)
      else
        @bookmark = fragment_at(line, column) unless @bookmark.try_merge!(line, column)
      end
      @bookmark
    end

    # @param range [Solargraph::Source::Range]
    def at range
      from_to range.start.line, range.start.character, range.ending.line, range.ending.character
    end

    def from_to l1, c1, l2, c2
      b = Solargraph::Source::Position.line_char_to_offset(@code, l1, c1)
      e = Solargraph::Source::Position.line_char_to_offset(@code, l2, c2)
      @code[b..e-1]
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

    # Locate the namespace pin at the specified line and character.
    #
    # @param line [line]
    # @param character [character]
    # @return [Pin::Namespace]
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
    # @param line [Integer]
    # @param column [Integer]
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
      return if @code == original_code or !reparse
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
      # return nil unless location.start_with?("#{filename}:")
      pins.select{|pin| pin.location == location}
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
        if top.children.any?{|c| c.to_s == name}
        # if top.children[0].to_s == name or (top.type == :const and top.children[1].to_s == name) or (top.type == :send and top.children[1].to_s == name)
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
      process_parsed node, comments
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

    def process_parsed node, comments
      new_map_data = Mapper.map(filename, code, node, comments)
      synchronize_mapped *new_map_data
    end

    def synchronize_mapped new_pins, new_locals, new_requires, new_symbols #, new_path_macros, new_domains
      return if @requires == new_requires and @symbols == new_symbols and try_merge(new_pins, new_locals)
      @pins = new_pins
      @locals = new_locals
      @requires = new_requires
      @symbols = new_symbols
      @all_symbols = nil # Reset for future queries
      @domains = []
      @path_macros = {}
      dirpins = []
      @pins.select(&:maybe_directives?).each do |pin|
        dirpins.push pin unless pin.directives.empty?
      end
      process_directives dirpins
      @stime = Time.now
    end

    # @param new_pins [Array<Solargraph::Pin::Base>]
    # @param new_locals [Array<Solargraph::Pin::Base>]
    # @return [Boolean]
    def try_merge new_pins, new_locals
      return false if @pins.nil? or @locals.nil? or new_pins.length != @pins.length or new_locals.length != @locals.length
      new_pins.each_index do |i|
        return false unless @pins[i].try_merge!(new_pins[i])
      end
      new_locals.each_index do |i|
        return false unless @locals[i].try_merge!(new_locals[i])
      end
      true
    end

    # @return [void]
    def process_directives pins
      pins.each do |pin|
        pin.directives.each do |d|
          # ns = namespace_for(k.node)
          ns = (pin.kind == Pin::NAMESPACE ? pin.path : pin.namespace)
          docstring = YARD::Docstring.parser.parse(d.tag.text).to_docstring
          if d.tag.tag_name == 'attribute'
            t = (d.tag.types.nil? || d.tag.types.empty?) ? nil : d.tag.types.flatten.join('')
            if t.nil? or t.include?('r')
              # location, namespace, name, docstring, access
              @pins.push Solargraph::Pin::Attribute.new(pin.location, pin.path, d.tag.name, docstring.all, :reader, :instance)
            end
            if t.nil? or t.include?('w')
              @pins.push Solargraph::Pin::Attribute.new(pin.location, pin.path, "#{d.tag.name}=", docstring.all, :writer, :instance)
            end
          elsif d.tag.tag_name == 'method'
            gen_src = Source.new("def #{d.tag.name};end", filename)
            gen_pin = gen_src.pins.last # Method is last pin after root namespace
            # next if ns.nil? or ns.empty? # @todo Add methods to global namespace?
            @pins.push Solargraph::Pin::Method.new(pin.location, pin.path, gen_pin.name, docstring.all, :instance, :public, [])
          elsif d.tag.tag_name == 'macro'
            @path_macros[pin.path] = d
          elsif d.tag.tag_name == 'domain'
            @domains.push d.tag.text
          else
            # STDERR.puts "Nothing to do for directive: #{d}"
          end
        end
      end
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
