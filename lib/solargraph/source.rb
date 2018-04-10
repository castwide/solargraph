require 'parser/current'
require 'time'

module Solargraph
  class Source
    autoload :FlawedBuilder, 'solargraph/source/flawed_builder'
    autoload :Fragment,      'solargraph/source/fragment'
    autoload :Position,      'solargraph/source/position'
    autoload :Range,         'solargraph/source/range'
    autoload :Updater,       'solargraph/source/updater'
    autoload :Change,        'solargraph/source/change'

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

    # def initialize code, node, comments, filename, stubbed_lines = []
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

    # @return [Array<String>]
    def namespaces
      @namespaces ||= namespace_pin_map.keys
    end

    def qualify(signature, fqns)
      return signature if signature.nil? or signature.empty?
      base, rest = signature.split('.', 2)
      parts = fqns.split('::')
      until parts.empty?
        here = parts.join('::')
        parts.pop
        name = "#{here}::#{base}"
        next if namespace_pins(name).empty?
        base = name
        break
      end
      base + (rest.nil? ? '' : ".#{rest}")
    end

    # @param fqns [String] The namespace (nil for all)
    # @return [Array<Solargraph::Pin::Namespace>]
    def namespace_pins fqns = nil
      return namespace_pin_map.values.flatten if fqns.nil?
      namespace_pin_map[fqns] || []
    end

    # @param fqns [String] The namespace (nil for all)
    # @return [Array<Solargraph::Pin::Method>]
    def method_pins fqns = nil
      return method_pin_map.values.flatten if fqns.nil?
      method_pin_map[fqns] || []
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

    # Get an array of nodes containing the specified index, starting with the
    # nearest node and ending with the root.
    #
    # @param index [Integer]
    # @return [Array<AST::Node>]
    def tree_at(line, column)
      # offset = get_parsed_offset(line, column)
      offset = Position.line_char_to_offset(@code, line, column)
      @all_nodes.reverse.each do |n|
        if n.respond_to?(:loc)
          if n.respond_to?(:begin) and n.respond_to?(:end)
            if offset >= n.begin.begin_pos and offset < n.end.end_pos
              return [n] + @node_tree[n.object_id]
            end
          elsif !n.loc.expression.nil?
            if offset >= n.loc.expression.begin_pos and offset < n.loc.expression.end_pos
              return [n] + @node_tree[n.object_id]
            end
          end
        end
      end
      [@node]
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
      Fragment.new(self, line, column, tree_at(line, column))
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
      node, comments = Source.parse(@fixed, filename)
      process_parsed node, comments
      @parsed = true
    end

    def hard_fix_node
      @fixed = @code.gsub(/[^\s]/, ' ')
      node, comments = Source.parse(@fixed, filename)
      process_parsed node, comments
      @parsed = false
    end

    def process_parsed node, comments
      root = AST::Node.new(:source, [filename])
      root = root.append node
      @node = root
      @namespaces = nil
      @comments = comments
      @directives = {}
      @path_macros = {}
      @docstring_hash = associate_comments(node, comments)
      @mtime = (!filename.nil? and File.exist?(filename) ? File.mtime(filename) : nil)
      @all_nodes = []
      @node_stack = []
      @node_tree = {}
      namespace_pin_map.clear
      namespace_pin_map[''] = [Solargraph::Pin::Namespace.new(self, @node, '', :public)]
      @namespace_pins = nil
      instance_variable_pins.clear
      class_variable_pins.clear
      local_variable_pins.clear
      symbol_pins.clear
      constant_pins.clear
      method_pin_map.clear
      # namespace_includes.clear
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
            gen_src = Source.new("def #{d.tag.name};end", filename)
            gen_pin = gen_src.method_pins.first
            method_pin_map[ns] ||= []
            method_pin_map[ns].push Solargraph::Pin::Directed::Method.new(gen_src, gen_pin.node, ns, :instance, :public, docstring, gen_pin.name)
          elsif d.tag.tag_name == 'macro'
            # @todo Handle various types of macros (attach, new, whatever)
            path = path_for(k.node)
            @path_macros[path] = v
          else
            STDERR.puts "Nothing to do for directive: #{d}"
          end
        end
      end
      @all_pins = namespace_pin_map.values.flatten + instance_variable_pins + class_variable_pins + local_variable_pins + symbol_pins + constant_pins + method_pins + attribute_pins
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

    def inner_map_node node, tree = [], visibility = :public, scope = :instance, fqn = '', stack = []
      stack.push node
      source = self
      if node.kind_of?(AST::Node)
        @all_nodes.push node
        @node_stack.unshift node
        if node.type == :class or node.type == :module
          visibility = :public
          if node.children[0].kind_of?(AST::Node) and node.children[0].children[0].kind_of?(AST::Node) and node.children[0].children[0].type == :cbase
            tree = pack_name(node.children[0])
          else
            tree = tree + pack_name(node.children[0])
          end
          fqn = tree.join('::')
          sc = nil
          nspin = Solargraph::Pin::Namespace.new(self, node, tree[0..-2].join('::') || '', :public, sc)
          if node.type == :class and !node.children[1].nil?
            nspin.reference_superclass unpack_name(node.children[1])
          end
          namespace_pin_map[nspin.path] ||= []
          namespace_pin_map[nspin.path].push nspin
        end
        file = source.filename
        node.children.each do |c|
          if c.kind_of?(AST::Node)
            @node_tree[c.object_id] = @node_stack.clone
            if c.type == :ivasgn
              par = find_parent(stack, :class, :module, :def, :defs)
              local_scope = ( (par.kind_of?(AST::Node) and par.type == :def) ? :instance : :class )
              if c.children[1].nil?
                ora = find_parent(stack, :or_asgn)
                unless ora.nil?
                  u = c.updated(:ivasgn, c.children + ora.children[1..-1], nil)
                  @all_nodes.push u
                  @node_tree[u.object_id] = @node_stack.clone
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
                  @node_tree[u.object_id] = @node_stack.clone
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
              method_pin_map[fqn || ''] ||= []
              method_pin_map[fqn || ''].push Solargraph::Pin::Method.new(source, c, fqn || '', scope, visibility)
            elsif c.type == :defs
              s_visi = visibility
              s_visi = :public if scope != :class
              if c.children[0].is_a?(AST::Node) and c.children[0].type == :self
                dfqn = fqn || ''
              else
                dfqn = unpack_name(c.children[0])
              end
              unless dfqn.nil?
                method_pin_map[dfqn] ||= []
                method_pin_map[dfqn].push Solargraph::Pin::Method.new(source, c, dfqn, :class, s_visi)
                inner_map_node c, tree, scope, :class, dfqn, stack
              end
              next
            elsif c.type == :send and [:public, :protected, :private].include?(c.children[1])
              visibility = c.children[1]
            elsif c.type == :send and [:private_class_method].include?(c.children[1]) and c.children[2].kind_of?(AST::Node)
              if c.children[2].type == :sym or c.children[2].type == :str
                ref = method_pins(fqn || '').select{|p| p.name == c.children[2].children[0].to_s}.first
                unless ref.nil?
                  method_pin_map[fqn || ''].delete ref
                  method_pin_map[fqn || ''].push Solargraph::Pin::Method.new(ref.source, ref.node, ref.namespace, ref.scope, :private)
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
                  ref = namespace_pin_map.values.flatten.select{|p| p.name == cn and p.namespace == fqn}.last
                  unless ref.nil?
                    namespace_pin_map[ref.path].delete ref
                    namespace_pin_map[ref.path].push Solargraph::Pin::Namespace.new(ref.source, ref.node, ref.namespace, :private, (ref.superclass_reference.nil? ? nil : ref.superclass_reference.name))
                  end
                else
                  source.constant_pins.delete ref
                  source.constant_pins.push Solargraph::Pin::Constant.new(ref.source, ref.node, ref.namespace, :private)
                end
              end
              next
            elsif c.type == :send and c.children[1] == :include and c.children[0].nil?
              if @node_tree[0].nil? or @node_tree[0].type == :source or @node_tree[0].type == :class or @node_tree[0].type == :module or (@node_tree.length > 1 and @node_tree[0].type == :begin and (@node_tree[1].type == :class or @node_tree[1].type == :module))
                if c.children[2].kind_of?(AST::Node) and c.children[2].type == :const
                  c.children[2..-1].each do |i|
                    namespace_pins(fqn || '').last.reference_include unpack_name(i)
                  end
                end
              end
            elsif c.type == :send and c.children[1] == :extend and c.children[0].nil?
              if @node_tree[0].nil? or @node_tree[0].type == :source or @node_tree[0].type == :class or @node_tree[0].type == :module or (@node_tree.length > 1 and @node_tree[0].type == :begin and (@node_tree[1].type == :class or @node_tree[1].type == :module))
                if c.children[2].kind_of?(AST::Node) and c.children[2].type == :const
                  # namespace_extends[fqn || ''] ||= []
                  c.children[2..-1].each do |i|
                    namespace_pin_map[fqn || ''].last.reference_extend unpack_name(i)
                  end
                end
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

      # @deprecated Use load_string instead
      # def virtual code, filename = nil
      #   load_string code, filename
      # end

      # @return [Solargraph::Source]
      def load_string code, filename = nil
        # source = Source.allocate
        # source.instance_variable_set(:@filename, filename)
        # source.reparse code
        # begin
        #   node, comments = parse(code, filename)
        #   Source.new(code, node, comments, filename)
        # rescue Parser::SyntaxError => e
        #   tmp = code.gsub(/[^ \t\r\n]/, ' ')
        #   node, comments = parse(tmp, filename)
        #   Source.new(code, node, comments, filename)
        # end
        Source.new code, filename
      end

      def parse code, filename = nil
        parser = Parser::CurrentRuby.new(FlawedBuilder.new)
        parser.diagnostics.all_errors_are_fatal = true
        parser.diagnostics.ignore_warnings      = true
        buffer = Parser::Source::Buffer.new(filename, 1)
        buffer.source = code
        parser.parse_with_comments(buffer)
      end

      def fix code, filename = nil, offset = nil
        tries = 0
        # code.gsub!(/\r/, '')
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
