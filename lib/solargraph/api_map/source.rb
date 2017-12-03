require 'parser/current'

module Solargraph
  class ApiMap
    class Source
      # @return [String]
      attr_reader :code

      # @return [Parser::AST::Node]
      attr_reader :node

      # @return [Array]
      attr_reader :comments

      # @return [String]
      attr_reader :filename

      # @return [Array<Integer>]
      attr_reader :stubbed_lines

      include NodeMethods

      def initialize code, node, comments, filename, stubbed_lines = []
        @code = code
        root = AST::Node.new(:source, [filename])
        root = root.append node
        @node = root
        @comments = comments
        @directives = {}
        @docstring_hash = associate_comments(node, comments)
        @filename = filename
        @namespace_nodes = {}
        @all_nodes = []
        @node_stack = []
        @node_tree = {}
        @stubbed_lines = stubbed_lines
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
            else
              STDERR.puts "Nothing to do for directive: #{d}"
            end
          end
        end
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

      # @return [String]
      def namespace_for node
        parts = []
        ([node] + (@node_tree[node] || [])).each do |n|
          if n.type == :class or n.type == :module
            parts.unshift unpack_name(n.children[0])
          end
        end
        parts.join('::')
      end

      def include? node
        @all_nodes.include? node
      end

      private

      def associate_comments node, comments
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
          @all_nodes.push node
          if node.type == :str or node.type == :dstr
            stack.pop
            return
          end
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
            namespace_pins.push Solargraph::Pin::Namespace.new(self, node, tree[0..-2].join('::') || '')
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
                constant_pins.push Solargraph::Pin::Constant.new(self, c, fqn)
              else
                if c.kind_of?(AST::Node)
                  if c.type == :def and c.children[0].to_s[0].match(/[a-z]/i)
                    method_pins.push Solargraph::Pin::Method.new(source, c, fqn || '', scope, visibility)
                  elsif c.type == :defs
                    method_pins.push Solargraph::Pin::Method.new(source, c, fqn || '', :class, :public)
                    inner_map_node c, tree, :public, :class, fqn, stack
                    next
                  elsif c.type == :send and [:public, :protected, :private].include?(c.children[1])
                    visibility = c.children[1]
                  elsif c.type == :send and c.children[1] == :include #and node.type == :class
                    namespace_includes[fqn] ||= []
                    c.children[2..-1].each do |i|
                      namespace_includes[fqn].push unpack_name(i)
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
                  end
                end
                if c.type == :send and c.children[1] == :require
                  if c.children[2].kind_of?(AST::Node) and c.children[2].type == :str
                    required.push c.children[2].children[0].to_s
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
  
      class << self
        # @return [Solargraph::ApiMap::Source]
        def load filename
          code = File.read(filename).gsub(/\r/, '')
          Source.virtual(code, filename)
        end

        # @return [Solargraph::ApiMap::Source]
        def virtual code, filename = nil
          node, comments = Parser::CurrentRuby.parse_with_comments(code)
          Source.new(code, node, comments, filename)
        end

        def get_position_at(code, offset)
          cursor = 0
          line = 0
          col = nil
          code.each_line do |l|
            if cursor + l.length >= offset
              col = offset - cursor
              break
            end
            cursor += l.length
            line += 1
          end
          raise "Invalid offset" if col.nil?
          [line, col]
        end

        def fix code, filename = nil, offset = nil
          tries = 0
          code.gsub!(/\r/, '')
          offset = CodeMap.get_offset(code, offset[0], offset[1]) if offset.kind_of?(Array)
          pos = nil
          pos = get_position_at(code, offset) unless offset.nil?
          stubs = []
          fixed_position = false
          tmp = code
          # Stub periods before the offset to retain the expected node tree
          if !offset.nil? and tmp[offset-1] == '.'
            tmp = tmp[0, offset-1] + '_' + tmp[offset..-1]
          end
          begin
            node, comments = Parser::CurrentRuby.parse_with_comments(tmp)
            Source.new(code, node, comments, filename, stubs)
          rescue Parser::SyntaxError => e
            if tries < 10
              tries += 1
              if !fixed_position and !offset.nil?
                fixed_position = true
                beg = beginning_of_line_from(tmp, offset)
                tmp = tmp[0, beg] + '#' + tmp[beg+1..-1]
                stubs.push(pos[0])
              elsif e.message.include?('token $end')
                tmp += "\nend"
              elsif e.message.include?("unexpected `@'")
                tmp = tmp[0, e.diagnostic.location.begin_pos] + '_' + tmp[e.diagnostic.location.begin_pos+1..-1]
              end
              retry
            end
            STDERR.puts "Unable to parse code: #{e.message}"
            virt = Source.virtual('', filename)
            Source.new(code, virt.node, virt.comments, filename)
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
end
