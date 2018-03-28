require 'parser/current'
require 'time'

module Solargraph
  class Source
    autoload :FlawedBuilder, 'solargraph/source/flawed_builder'
    autoload :Fragment,      'solargraph/source/fragment'

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

    # @return [Array<Integer>]
    attr_reader :stubbed_lines

    attr_reader :directives

    attr_reader :path_macros

    attr_accessor :version

    # Get the time of the last synchronization.
    #
    # @return [Time]
    attr_reader :stime

    include NodeMethods

    def initialize code, node, comments, filename, stubbed_lines = []
      @code = code
      @fixed = code
      @filename = filename
      @stubbed_lines = stubbed_lines
      @version = 0
      process_parsed node, comments
    end

    def macro path
      @path_macros[path]
    end

    def namespaces
      @namespace_nodes.keys
    end

    def namespace_nodes
      @namespace_nodes
    end

    def namespace_includes
      @namespace_includes ||= {}
    end

    def namespace_extends
      @namespaces_extends ||= {}
    end

    def superclasses
      @superclasses ||= {}
    end

    # @return [Array<Solargraph::Pin::Method>]
    def method_pins
      @method_pins ||= []
    end

    # @return [Array<Solargraph::Pin::Attribute>]
    def attribute_pins
      @attribute_pins ||= []
    end

    # @return [Array<Solargraph::Pin::InstanceVariable>]
    def instance_variable_pins
      @instance_variable_pins ||= []
    end

    # @return [Array<Solargraph::Pin::ClassVariable>]
    def class_variable_pins
      @class_variable_pins ||= []
    end

    # @return [Array<Solargraph::Pin::LocalVariable>]
    def local_variable_pins
      @local_variable_pins ||= []
    end

    # @return [Array<Solargraph::Pin::GlobalVariable>]
    def global_variable_pins
      @global_variable_pins ||= []
    end

    # @return [Array<Solargraph::Pin::Constant>]
    def constant_pins
      @constant_pins ||= []
    end

    # @return [Array<Solargraph::Pin::Symbol>]
    def symbol_pins
      @symbol_pins ||= []
    end

    # @return [Array<Solargraph::Pin::Namespace>]
    def namespace_pins
      @namespace_pins ||= []
    end

    # @return [Array<String>]
    def required
      @required ||= []
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

    def tree_for node
      @node_tree[node] || []
    end

    # Determine if the specified index is inside a string.
    #
    # @return [Boolean]
    def string_at?(index)
      n = node_at(index)
      n.kind_of?(AST::Node) and (n.type == :str or n.type == :dstr)
    end

    # Get the nearest node that contains the specified index.
    #
    # @param index [Integer]
    # @return [AST::Node]
    def node_at(index)
      tree_at(index).first
    end

    # Get an array of nodes containing the specified index, starting with the
    # nearest node and ending with the root.
    #
    # @param index [Integer]
    # @return [Array<AST::Node>]
    def tree_at(index)
      arr = []
      arr.push @node
      inner_node_at(index, @node, arr)
      arr
    end

    # Find the nearest parent node from the specified index. If one or more
    # types are provided, find the nearest node whose type is in the list.
    #
    # @param index [Integer]
    # @param types [Array<Symbol>]
    # @return [AST::Node]
    def parent_node_from(index, *types)
      arr = tree_at(index)
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
      ([node] + (@node_tree[node] || [])).each do |n|
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

    def synchronize changes, version
      changes.each do |change|
        reparse change
      end
      @version = version
      self
    end

    def get_offset line, col
      Source.get_offset(code, line, col)
    end

    def self.get_offset text, line, col
      offset = 0
      if line > 0
        text.lines[0..line - 1].each { |l|
          offset += l.length
        }
      end
      offset + col
    end

    def overwrite text
      reparse({'text' => text})
    end

    def query_symbols query
      return [] if query.empty?
      down = query.downcase
      all_symbols.select{|p| p.path.downcase.include?(down)}
    end
    
    def all_symbols
      result = []
      result.concat namespace_pins
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
      Fragment.new(self, get_offset(line, column))
    end

    private

    def inner_node_at(index, node, arr)
      node.children.each do |c|
        if c.kind_of?(AST::Node) and c.respond_to?(:loc)
          unless c.loc.expression.nil?
            if index >= c.loc.expression.begin_pos
              if c.respond_to?(:end)
                if index < c.end.end_pos
                  arr.unshift c
                end
              elsif index < c.loc.expression.end_pos
                arr.unshift c
              end
            end
          end
          inner_node_at(index, c, arr)
        end
      end
    end

    def reparse change
      if change['range']
        start_offset = Source.get_offset(@code, change['range']['start']['line'], change['range']['start']['character'])
        end_offset = Source.get_offset(@code, change['range']['end']['line'], change['range']['end']['character'])
        rewrite = (start_offset == 0 ? '' : @code[0..start_offset-1].to_s) + change['text'].gsub(/\r\n/, "\n").force_encoding('utf-8') + @code[end_offset..-1].to_s
        return if @code == rewrite
        again = true
        if change['text'].match(/^[^a-z0-9\s]*$/i)
          tmp = (start_offset == 0 ? '' : @code[0..start_offset-1].to_s) + change['text'].gsub(/\r\n/, "\n").gsub(/[^\s]/, ' ') + @code[end_offset..-1].to_s
          again = false
        else
          tmp = rewrite
        end
        @code = rewrite
        begin
          node, comments = Source.parse(tmp, filename)
          process_parsed node, comments
          @fixed = tmp
        rescue Parser::SyntaxError => e
          if again
            again = false
            tmp = (start_offset == 0 ? '' : @fixed[0..start_offset-1].to_s) + change['text'].gsub(/\r\n/, "\n").gsub(/[^\s]/, ' ') + @fixed[end_offset..-1].to_s
            retry
          else
            hard_fix_node
          end
        end
      else
        tmp = change['text'].gsub(/\r\n/, "\n")
        return if @code == tmp
        @code = tmp
        begin
          node, comments = Source.parse(@code, filename)
          process_parsed node, comments
          @fixed = @code
        rescue Parser::SyntaxError => e
          hard_fix_node
        end
      end
    end

    def hard_fix_node
      tmp = @code.gsub(/[^ \t\r\n]/, ' ')
      @fixed = tmp
      node, comments = Source.parse(tmp, filename)
      process_parsed node, comments
    end

    def process_parsed node, comments
      root = AST::Node.new(:source, [filename])
      root = root.append node
      @node = root
      @comments = comments
      @directives = {}
      @path_macros = {}
      @docstring_hash = associate_comments(node, comments)
      @mtime = (!filename.nil? and File.exist?(filename) ? File.mtime(filename) : nil)
      @namespace_nodes = {}
      @all_nodes = []
      @node_stack = []
      @node_tree = {}
      namespace_pins.clear
      instance_variable_pins.clear
      class_variable_pins.clear
      local_variable_pins.clear
      symbol_pins.clear
      constant_pins.clear
      method_pins.clear
      namespace_includes.clear
      namespace_extends.clear
      superclasses.clear
      attribute_pins.clear
      @node_object_ids = nil
      inner_map_node @node
      @directives.each_pair do |k, v|
        v.each do |d|
          ns = namespace_for(k.node)
          docstring = YARD::Docstring.parser.parse(d.tag.text).to_docstring
          if d.tag.tag_name == 'attribute'
            t = (d.tag.types.nil? || d.tag.types.empty?) ? nil : d.tag.types.flatten.join('')
            if t.nil? or t.include?('r')
              attribute_pins.push Solargraph::Pin::Directed::Attribute.new(self, k.node, ns, :reader, docstring, d.tag.name)
            end
            if t.nil? or t.include?('w')
              attribute_pins.push Solargraph::Pin::Directed::Attribute.new(self, k.node, ns, :writer, docstring, "#{d.tag.name}=")
            end
          elsif d.tag.tag_name == 'method'
            gen_src = Source.virtual("def #{d.tag.name};end", filename)
            gen_pin = gen_src.method_pins.first
            method_pins.push Solargraph::Pin::Directed::Method.new(gen_src, gen_pin.node, ns, :instance, :public, docstring, gen_pin.name)
          elsif d.tag.tag_name == 'macro'
            # @todo Handle various types of macros (attach, new, whatever)
            path = path_for(k.node)
            @path_macros[path] = v
          else
            STDERR.puts "Nothing to do for directive: #{d}"
          end
        end
      end
      @all_pins = namespace_pins + instance_variable_pins + class_variable_pins + local_variable_pins + symbol_pins + constant_pins + method_pins + attribute_pins
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

    def inner_map_node node, tree = [], visibility = :public, scope = :instance, fqn = nil, stack = []
      stack.push node
      source = self
      if node.kind_of?(AST::Node)
        # @node_tree[node] = @node_stack.clone
        @all_nodes.push node
        # if node.type == :str or node.type == :dstr
        #   stack.pop
        #   return
        # end
        @node_stack.unshift node
        if node.type == :class or node.type == :module
          visibility = :public
          if node.children[0].kind_of?(AST::Node) and node.children[0].children[0].kind_of?(AST::Node) and node.children[0].children[0].type == :cbase
            tree = pack_name(node.children[0])
          else
            tree = tree + pack_name(node.children[0])
          end
          fqn = tree.join('::')
          @namespace_nodes[fqn] ||= []
          @namespace_nodes[fqn].push node
          namespace_pins.push Solargraph::Pin::Namespace.new(self, node, tree[0..-2].join('::') || '', :public)
          if node.type == :class and !node.children[1].nil?
            sc = unpack_name(node.children[1])
            superclasses[fqn] = sc
          end
        end
        file = source.filename
        node.children.each do |c|
          if c.kind_of?(AST::Node)
            @node_tree[c] = @node_stack.clone
            if c.type == :ivasgn
              par = find_parent(stack, :class, :module, :def, :defs)
              local_scope = ( (par.kind_of?(AST::Node) and par.type == :def) ? :instance : :class )
              if c.children[1].nil?
                ora = find_parent(stack, :or_asgn)
                unless ora.nil?
                  u = c.updated(:ivasgn, c.children + ora.children[1..-1], nil)
                  @all_nodes.push u
                  @node_tree[u] = @node_stack.clone
                  @docstring_hash[u.loc] = docstring_for(ora)
                  instance_variable_pins.push Solargraph::Pin::InstanceVariable.new(self, u, fqn || '', local_scope)
                end
              else
                instance_variable_pins.push Solargraph::Pin::InstanceVariable.new(self, c, fqn || '', local_scope)
              end
            elsif c.type == :cvasgn
              if c.children[1].nil?
                ora = find_parent(stack, :or_asgn)
                unless ora.nil?
                  u = c.updated(:cvasgn, c.children + ora.children[1..-1], nil)
                  @node_tree[u] = @node_stack.clone
                  @all_nodes.push u
                  @docstring_hash[u.loc] = docstring_for(ora)
                  class_variable_pins.push Solargraph::Pin::ClassVariable.new(self, u, fqn || '')
                end
              else
                class_variable_pins.push Solargraph::Pin::ClassVariable.new(self, c, fqn || '')
              end
            elsif c.type == :lvasgn
              if c.children[1].nil?
                ora = find_parent(stack, :or_asgn)
                unless ora.nil?
                  u = c.updated(:lvasgn, c.children + ora.children[1..-1], nil)
                  @all_nodes.push u
                  @node_tree[u] = @node_stack.clone
                  @docstring_hash[u.loc] = docstring_for(ora)
                  local_variable_pins.push Solargraph::Pin::LocalVariable.new(self, u, fqn || '', @node_stack.clone)
                end
              else
                @node_tree[c] = @node_stack.clone
                local_variable_pins.push Solargraph::Pin::LocalVariable.new(self, c, fqn || '', @node_stack.clone)
              end
            elsif c.type == :gvasgn
              global_variable_pins.push Solargraph::Pin::GlobalVariable.new(self, c, fqn || '')
            elsif c.type == :sym
              symbol_pins.push Solargraph::Pin::Symbol.new(self, c, fqn)
            elsif c.type == :casgn
              constant_pins.push Solargraph::Pin::Constant.new(self, c, fqn, :public)
            elsif c.type == :def and c.children[0].to_s[0].match(/[a-z]/i)
              method_pins.push Solargraph::Pin::Method.new(source, c, fqn || '', scope, visibility)
            elsif c.type == :defs
              s_visi = visibility
              s_visi = :public if scope != :class
              method_pins.push Solargraph::Pin::Method.new(source, c, fqn || '', :class, s_visi)
              inner_map_node c, tree, scope, :class, fqn, stack
              next
            elsif c.type == :send and [:public, :protected, :private].include?(c.children[1])
              visibility = c.children[1]
            elsif c.type == :send and [:private_class_method].include?(c.children[1]) and c.children[2].kind_of?(AST::Node)
              if c.children[2].type == :sym or c.children[2].type == :str
                ref = method_pins.select{|p| p.name == c.children[2].children[0].to_s}.first
                unless ref.nil?
                  source.method_pins.delete ref
                  source.method_pins.push Solargraph::Pin::Method.new(ref.source, ref.node, ref.namespace, ref.scope, :private)
                end
              else
                inner_map_node c, tree, :private, :class, fqn, stack
                next
              end
            elsif c.type == :send and [:private_constant].include?(c.children[1]) and c.children[2].kind_of?(AST::Node)
              if c.children[2].type == :sym or c.children[2].type == :str
                cn = c.children[2].children[0].to_s
                ref = constant_pins.select{|p| p.name == cn}.first
                if ref.nil?
                  ref = namespace_pins.select{|p| p.name == cn}.first
                  unless ref.nil?
                    source.namespace_pins.delete ref
                    source.namespace_pins.push Solargraph::Pin::Namespace.new(ref.source, ref.node, ref.namespace, :private)
                  end
                else
                  source.constant_pins.delete ref
                  source.constant_pins.push Solargraph::Pin::Constant.new(ref.source, ref.node, ref.namespace, :private)
                end
              end
              next
            elsif c.type == :send and c.children[1] == :include
              namespace_includes[fqn] ||= []
              c.children[2..-1].each do |i|
                namespace_includes[fqn].push unpack_name(i)
              end
            elsif c.type == :send and c.children[1] == :extend
              namespace_extends[fqn] ||= []
              c.children[2..-1].each do |i|
                namespace_extends[fqn].push unpack_name(i)
              end
            elsif c.type == :send and [:attr_reader, :attr_writer, :attr_accessor].include?(c.children[1])
              c.children[2..-1].each do |a|
                if c.children[1] == :attr_reader or c.children[1] == :attr_accessor
                  attribute_pins.push Solargraph::Pin::Attribute.new(self, a, fqn || '', :reader, docstring_for(c)) #AttrPin.new(c)
                end
                if c.children[1] == :attr_writer or c.children[1] == :attr_accessor
                  attribute_pins.push Solargraph::Pin::Attribute.new(self, a, fqn || '', :writer, docstring_for(c)) #AttrPin.new(c)
                end
              end
            elsif c.type == :sclass and c.children[0].type == :self
              inner_map_node c, tree, :public, :class, fqn || '', stack
              next
            elsif c.type == :send and c.children[1] == :require
              if c.children[2].kind_of?(AST::Node) and c.children[2].type == :str
                required.push c.children[2].children[0].to_s
              end
            elsif c.type == :args
              if @node_stack.first.type == :block
                pi = 0
                c.children.each do |u|
                  local_variable_pins.push Solargraph::Pin::BlockParameter.new(self, u, fqn || '', @node_stack.clone, pi)
                  pi += 1
                end
              else
                c.children.each do |u|
                  local_variable_pins.push Solargraph::Pin::MethodParameter.new(self, u, fqn || '', @node_stack.clone)
                end
              end
            end
            inner_map_node c, tree, visibility, scope, fqn, stack
          end
        end
        @node_stack.shift
      end
      stack.pop
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

    class << self
      # @return [Solargraph::Source]
      def load filename
        code = File.read(filename).gsub(/\r/, '')
        Source.load_string(code, filename)
      end

      # @deprecated Use load_string instead
      def virtual code, filename = nil
        load_string code, filename
      end

      # @return [Solargraph::Source]
      def load_string code, filename = nil
        begin
          node, comments = parse(code, filename)
          Source.new(code, node, comments, filename)
        rescue Parser::SyntaxError => e
          tmp = code.gsub(/[^ \t\r\n]/, ' ')
          node, comments = parse(tmp, filename)
          Source.new(code, node, comments, filename)
        end
      end

      def get_position_at(code, offset)
        cursor = 0
        line = 0
        col = nil
        code.each_line do |l|
          if cursor + l.length > offset
            col = offset - cursor
            break
          end
          if cursor + l.length == offset
            if l.end_with?("\n")
              col = 0
              line += 1
              break
            else
              col = l.length
              break
            end
          end
          # if cursor + l.length - 1 == offset and !l.end_with?("\n")
          #   col = l.length - 1
          #   break
          # end
          cursor += l.length
          line += 1
        end
        raise "Invalid offset" if col.nil?
        [line, col]
      end

      def parse code, filename = nil
        parser = Parser::CurrentRuby.new(FlawedBuilder.new)
        parser.diagnostics.all_errors_are_fatal = true
        parser.diagnostics.ignore_warnings      = true
        buffer = Parser::Source::Buffer.new(filename, 1)
        buffer.source = code.gsub(/\r\n/, "\n")
        parser.parse_with_comments(buffer)
      end  

      def fix code, filename = nil, offset = nil
        tries = 0
        code.gsub!(/\r/, '')
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
