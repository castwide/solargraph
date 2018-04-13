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

    attr_reader :pins

    attr_reader :requires

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
      rescue Parser::SyntaxError
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
      # @namespaces ||= namespace_pin_map.keys
      @namespaces ||= pins.select{|pin| pin.kind == Pin::NAMESPACE}.map(&:path)
    end

    # @param fqns [String] The namespace (nil for all)
    # @return [Array<Solargraph::Pin::Namespace>]
    def namespace_pins fqns = nil
      # return namespace_pin_map.values.flatten if fqns.nil?
      # namespace_pin_map[fqns] || []
      @namespace_pins ||= pins.select{|pin| pin.kind == Pin::NAMESPACE}
    end

    # @param fqns [String] The namespace (nil for all)
    # @return [Array<Solargraph::Pin::Method>]
    def method_pins fqns = nil
      # return method_pin_map.values.flatten if fqns.nil?
      # method_pin_map[fqns] || []
      @method_pins ||= pins.select{|pin| pin.kind == Solargraph::Pin::METHOD}
    end

    # @return [Array<Solargraph::Pin::Attribute>]
    def attribute_pins
      @attribute_pins ||= pins.select{|pin| pin.kind == Pin::ATTRIBUTE}
    end

    # @return [Array<Solargraph::Pin::InstanceVariable>]
    def instance_variable_pins
      @instance_variable_pins ||= pins.select{|pin| pin.kind == Pin::INSTANCE_VARIABLE}
    end

    # @return [Array<Solargraph::Pin::ClassVariable>]
    def class_variable_pins
      @class_variable_pins ||= pins.select{|pin| pin.kind == Pin::CLASS_VARIABLE}
    end

    def locals
      @locals
    end

    # @return [Array<Solargraph::Pin::GlobalVariable>]
    def global_variable_pins
      @global_variable_pins ||= pins.select{|pin| pin.kind == Pin::GLOBAL_VARIABLE}
    end

    # @return [Array<Solargraph::Pin::Constant>]
    def constant_pins
      @constant_pins ||= pins.select{|pin| pin.kind == Pin::CONSTANT}
    end

    # @return [Array<Solargraph::Pin::Symbol>]
    def symbol_pins
      @symbols
    end

    def symbols
      symbol_pins
    end

    # # @return [Array<String>]
    # def required
    #   @required ||= []
    # end

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
      found
    end

    # @return [YARD::Docstring]
    def docstring_for node
      return @docstring_hash[node.loc] if node.respond_to?(:loc)
      nil
    end

    # @return [String]
    def code_for node
      b = node.location.expression.begin.begin_pos
      e = node.location.expression.end.end_pos
      frag = code[b..e-1].to_s
      frag.strip.gsub(/,$/, '')
    end

    # @param node [Parser::AST::Node]
    def tree_for node
      @node_tree[node.object_id] || []
    end

    # Get the nearest node that contains the specified index.
    #
    # @param index [Integer]
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
      # offset = get_parsed_offset(line, column)
      offset = Position.line_char_to_offset(@code, line, column)
      # @all_nodes.reverse.each do |n|
      #   if n.respond_to?(:loc)
      #     if n.respond_to?(:begin) and n.respond_to?(:end)
      #       if offset >= n.begin.begin_pos and offset < n.end.end_pos
      #         return [n] + @node_tree[n.object_id]
      #       end
      #     elsif !n.loc.expression.nil?
      #       if offset >= n.loc.expression.begin_pos and offset < n.loc.expression.end_pos
      #         return [n] + @node_tree[n.object_id]
      #       end
      #     end
      #   end
      # end
      # [@node]
      stack = []
      inner_tree_at @node, offset, stack
      stack
    end

    def inner_tree_at node, offset, stack
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

    # Find the nearest parent node from the specified index. If one or more
    # types are provided, find the nearest node whose type is in the list.
    #
    # @param index [Integer]
    # @param types [Array<Symbol>]
    # @return [AST::Node]
    def parent_node_from(line, column, *types)
      arr = tree_at(line, column)
      arr.each { |a|
        if a.kind_of?(AST::Node) and (types.empty? or types.include?(a.type))
          return a
        end
      }
      nil
    end

    # @return [String]
    def namespace_for node
      parts = []
      ([node] + (@node_tree[node.object_id] || [])).each do |n|
        next unless n.kind_of?(AST::Node)
        if n.type == :class or n.type == :module
          parts.unshift unpack_name(n.children[0])
        end
      end
      parts.join('::')
    end

    def path_for node
      path = namespace_for(node) || ''
      mp = (method_pins + attribute_pins).select{|p| p.node == node}.first
      unless mp.nil?
        path += (mp.scope == :instance ? '#' : '.') + mp.name
      end
      path
    end

    def include? node
      node_object_ids.include? node.object_id
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
      rescue Parser::SyntaxError => e
        @fixed = updater.repair(original_fixed)
        begin
          parse
        rescue Parser::SyntaxError => e
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
      result.concat namespace_pin_map.values.flatten
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

    def fragment_for node
      inside = tree_for(node)
      return nil if inside.empty?
      line = node.loc.expression.last_line - 1
      column = node.loc.expression.last_column
      Fragment.new(self, line, column, inside)
    end

    def parsed?
      @parsed
    end

    private

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
      buffer.source = code.force_encoding(Encoding::UTF_8)
      parser.parse_with_comments(buffer)
    end

    def process_parsed node, comments
      @pins, @locals, @requires, @symbols, @path_macros = Mapper.map filename, code, node, comments
      # @directives.each_pair do |k, v|
      #   v.each do |d|
      #     ns = namespace_for(k.node)
      #     docstring = YARD::Docstring.parser.parse(d.tag.text).to_docstring
      #     if d.tag.tag_name == 'attribute'
      #       t = (d.tag.types.nil? || d.tag.types.empty?) ? nil : d.tag.types.flatten.join('')
      #       if t.nil? or t.include?('r')
      #         attribute_pins.push Solargraph::Pin::Directed::Attribute.new(self, k.node, ns, :reader, docstring, d.tag.name)
      #       end
      #       if t.nil? or t.include?('w')
      #         attribute_pins.push Solargraph::Pin::Directed::Attribute.new(self, k.node, ns, :writer, docstring, "#{d.tag.name}=")
      #       end
      #     elsif d.tag.tag_name == 'method'
      #       gen_src = Source.new("def #{d.tag.name};end", filename)
      #       gen_pin = gen_src.method_pins.first
      #       method_pin_map[ns] ||= []
      #       method_pin_map[ns].push Solargraph::Pin::Directed::Method.new(gen_src, gen_pin.node, ns, :instance, :public, docstring, gen_pin.name)
      #     elsif d.tag.tag_name == 'macro'
      #       # @todo Handle various types of macros (attach, new, whatever)
      #       path = path_for(k.node)
      #       @path_macros[path] = v
      #     else
      #       STDERR.puts "Nothing to do for directive: #{d}"
      #     end
      #   end
      # end
      @stime = Time.now
    end

    def associate_comments node, comments
      return nil if comments.nil?
      comment_hash = Parser::Source::Comment.associate_locations(node, comments)
      yard_hash = {}
      comment_hash.each_pair { |k, v|
        ctxt = ''
        num = nil
        started = false
        v.each { |l|
          # Trim the comment and minimum leading whitespace
          p = l.text.gsub(/^#/, '')
          if num.nil? and !p.strip.empty?
            num = p.index(/[^ ]/)
            started = true
          elsif started and !p.strip.empty?
            cur = p.index(/[^ ]/)
            num = cur if cur < num
          end
          if started
            ctxt += "#{p[num..-1]}\n"
          end
        }
        parse = YARD::Docstring.parser.parse(ctxt)
        unless parse.directives.empty?
          @directives[k] ||= []
          @directives[k].concat parse.directives
        end
        yard_hash[k] = parse.to_docstring
      }
      yard_hash
    end

    def find_parent(stack, *types)
      stack.reverse.each { |p|
        return p if types.include?(p.type)
      }
      nil
    end

    def node_object_ids
      @node_object_ids ||= @all_nodes.map(&:object_id)
    end

    # @return [Hash<String, Solargraph::Pin::Namespace>]
    def namespace_pin_map
      @namespace_pin_map ||= {}
    end

    # @return [Hash<String, Solargraph::Pin::Namespace>]
    def method_pin_map
      @method_pin_map ||= {}
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

      def fix code, filename = nil, offset = nil
        tries = 0
        offset = Source.get_offset(code, offset[0], offset[1]) if offset.kind_of?(Array)
        pos = nil
        pos = get_position_at(code, offset) unless offset.nil?
        stubs = []
        fixed_position = false
        tmp = code.sub(/\.(\s*\z)$/, ' \1')
        begin
          node, comments = Source.parse(tmp, filename)
          Source.new(code, node, comments, filename, stubs)
        rescue Parser::SyntaxError => e
          if tries < 10
            tries += 1
            # Stub periods before the offset to retain the expected node tree
            if !offset.nil? and ['.', '{', '('].include?(tmp[offset-1])
              tmp = tmp[0, offset-1] + ';' + tmp[offset..-1]
            elsif !fixed_position and !offset.nil?
              fixed_position = true
              beg = beginning_of_line_from(tmp, offset)
              tmp = "#{tmp[0, beg]}##{tmp[beg+1..-1]}"
              stubs.push(pos[0])
            elsif e.message.include?('token $end')
              tmp += "\nend"
            elsif e.message.include?("unexpected `@'")
              tmp = tmp[0, e.diagnostic.location.begin_pos] + '_' + tmp[e.diagnostic.location.begin_pos+1..-1]
            end
            retry
          end
          STDERR.puts "Unable to parse file #{filename.nil? ? 'undefined' : filename}: #{e.message}"
          node, comments = parse(code.gsub(/[^\s]/, ' '), filename)
          Source.new(code, node, comments, filename)
        end
      end

      def beginning_of_line_from str, i
        while i > 0 and str[i-1] != "\n"
          i -= 1
        end
        i
      end
    end
  end
end
