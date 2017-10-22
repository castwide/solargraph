require 'parser/current'

module Solargraph
  class ApiMap
    class Source
      attr_reader :code
      attr_reader :node
      attr_reader :comments
      attr_reader :filename

      include NodeMethods

      def initialize code, node, comments, filename
        @code = code
        root = AST::Node.new(:source, [filename])
        root = root.append node
        @node = root
        @comments = comments
        @docstring_hash = associate_comments(node, comments)
        @filename = filename
        @namespace_nodes = {}
        @all_nodes = []
        @node_stack = []
        @node_tree = {}
        inner_map_node @node
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

      def method_pins
        @method_pins ||= []
      end

      def attribute_pins
        @attribute_pins ||= []
      end

      def instance_variable_pins
        @instance_variable_pins ||= []
      end

      def class_variable_pins
        @class_variable_pins ||= []
      end

      def local_variable_pins
        @local_variable_pis ||= []
      end

      def constant_pins
        @constant_pins ||= []
      end

      def symbol_pins
        @symbol_pins ||= []
      end

      def required
        @required ||= []
      end

      def docstring_for node
        @docstring_hash[node.loc]
      end

      def code_for node
        b = node.location.expression.begin.begin_pos
        e = node.location.expression.end.end_pos
        frag = code[b..e-1].to_s
        frag.strip.gsub(/,$/, '')
      end

      def tree_for node
        @node_tree[node] || []
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
          yard_hash[k] = YARD::Docstring.parser.parse(ctxt).to_docstring
        }
        yard_hash
      end
  
      def inner_map_node node, tree = [], visibility = :public, scope = :instance, fqn = nil, stack = []
        stack.push node
        source = self
        if node.kind_of?(AST::Node)
          @all_nodes.push node
          return if node.type == :str or node.type == :dstr
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
            if node.type == :class and !node.children[1].nil?
              sc = unpack_name(node.children[1])
              superclasses[fqn] = sc
            end
          end
          file = source.filename
          @node_stack.unshift node
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
                    local_variable_pins.push Solargraph::Pin::LocalVariable.new(self, u, fqn || '', @node_stack.clone)
                  end
                else
                  local_variable_pins.push Solargraph::Pin::LocalVariable.new(self, c, fqn || '', @node_stack.clone)
                end
              elsif c.type == :sym
                symbol_pins.push Solargraph::Pin::Symbol.new(self, c, fqn)
              elsif c.type == :casgn
                constant_pins.push Solargraph::Pin::Constant.new(self, c, fqn)
              else
                unless fqn.nil?
                  if c.kind_of?(AST::Node)
                    if c.type == :def and c.children[0].to_s[0].match(/[a-z]/i)
                      method_pins.push Solargraph::Pin::Method.new(source, c, fqn, scope, visibility)
                      inner_map_node c, tree, visibility, scope, fqn, stack
                      next
                    elsif c.type == :defs
                      method_pins.push Solargraph::Pin::Method.new(source, c, fqn, :class, :public)
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
                          attribute_pins.push Solargraph::Pin::Attribute.new(self, a, fqn, :reader, docstring_for(c)) #AttrPin.new(c)
                        end
                        if c.children[1] == :attr_writer or c.children[1] == :attr_accessor
                          attribute_pins.push Solargraph::Pin::Attribute.new(self, a, fqn, :writer, docstring_for(c)) #AttrPin.new(c)
                        end
                      end
                    elsif c.type == :sclass and c.children[0].type == :self
                      inner_map_node c, tree, :public, :class, fqn, stack
                      next
                    end
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
          Source.virtual(filename, code)
        end

        # @return [Solargraph::ApiMap::Source]
        def virtual filename, code
          node, comments = Parser::CurrentRuby.parse_with_comments(code)
          Source.new(code, node, comments, filename)
        end

        # @return [Solargraph::ApiMap::Source]
        def fix filename, code, cursor = nil
          tries = 0
          code.gsub!(/\r/, '')
          tmp = code
          cursor = CodeMap.get_offset(code, cursor[0], cursor[1]) if cursor.kind_of?(Array)
          fixed_cursor = false
          begin
            # HACK: The current file is parsed with a trailing underscore to fix
            # incomplete trees resulting from short scripts (e.g., a lone variable
            # assignment).
            node, comments = Parser::CurrentRuby.parse_with_comments(tmp + "\n_")
            Source.new(code, node, comments, filename)
          rescue Parser::SyntaxError => e
            if tries < 10
              tries += 1
              if tries == 10 and e.message.include?('token $end')
                tmp += "\nend"
              else
                if !fixed_cursor and !cursor.nil? and e.message.include?('token $end') and cursor >= 2
                  fixed_cursor = true
                  spot = cursor - 2
                  if tmp[cursor - 1] == '.'
                    repl = ';'
                  else
                    repl = '#'
                  end
                else
                  spot = e.diagnostic.location.begin_pos
                  repl = '_'
                  if tmp[spot] == '@' or tmp[spot] == ':'
                    # Stub unfinished instance variables and symbols
                    spot -= 1
                  elsif tmp[spot - 1] == '.'
                    # Stub unfinished method calls
                    repl = '#' if spot == tmp.length or tmp[spot] == '\n'
                    spot -= 2
                  else
                    # Stub the whole line
                    spot = beginning_of_line_from(tmp, spot)
                    repl = '#'
                    if tmp[spot+1..-1].rstrip == 'end'
                      repl= 'end;end'
                    end
                  end
                end
                tmp = tmp[0..spot] + repl + tmp[spot+repl.length+1..-1].to_s
              end
              retry
            end
            raise e
          end
        end

        def beginning_of_line_from str, i
          while i > 0 and str[i] != "\n"
            i -= 1
          end
          if i > 0 and str[i..-1].strip == ''
            i = beginning_of_line_from str, i -1
          end
          i
        end
      end
    end
  end
end
