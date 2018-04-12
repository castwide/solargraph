module Solargraph
  class Source
    class Mapper
      include NodeMethods

      private_class_method :new

      # @return [Array<Solargraph::Pin::Base>]
      def map filename, code, node, comments
        @filename = filename
        @code = code
        @node = node
        @comments = comments
        @node_stack = []
        @node_tree = []
        @comment_hash = {}
        @directives = {}
        @docstring_hash = associate_comments(node, comments)
        # @todo Stuff that needs to be resolved
        @variables = []

        @pins = []
        @requires = []
        @symbols = []
        @locals = []

        # HACK make sure the first node gets processed
        root = AST::Node.new(:source, [filename])
        root = root.append node
        process root
        [@pins, @locals, @requires, @symbols]
      end

      class << self
        # @return [Array<Solargraph::Pin::Base>]
        def map filename, code, node, comments
          new.map filename, code, node, comments
        end
      end

      # @return [String]
      def code_for node
        b = node.location.expression.begin.begin_pos
        e = node.location.expression.end.end_pos
        frag = @code[b..e-1].to_s
        frag.strip.gsub(/,$/, '')
      end

      def comment_hash
        @comment_hash
      end

      def filename
        @filename
      end

      def comments
        @comments
      end

      def pins
        @pins ||= []
      end

      def process node, tree = [], visibility = :public, scope = :instance, fqn = '', stack = []
        stack.push node
        if node.kind_of?(AST::Node)
          # @all_nodes.push node
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
            if node.type == :class and !node.children[1].nil?
              sc = unpack_name(node.children[1])
            end
            pins.push Solargraph::Pin::Namespace.new(get_node_location(node), tree[0..-2].join('::') || '', pack_name(node.children[0]).last.to_s, docstring_for(node), :class, visibility, sc)
            # namespace_pin_map[nspin.path] ||= []
            # namespace_pin_map[nspin.path].push nspin
            # get_node_range(node)
            # namespaces.add nspin.path
          end
          file = filename
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
                    # @all_nodes.push u
                    @node_tree[u.object_id] = @node_stack.clone
                    @docstring_hash[u.loc] = docstring_for(ora)
                    # instance_variable_pins.push Solargraph::Pin::InstanceVariable.new(self, u, fqn || '', local_scope)
                    pins.push Solargraph::Pin::InstanceVariable.new(get_node_location(u), fqn || '', c.children[0].to_s, docstring_for(u), local_scope)
                  end
                else
                  # instance_variable_pins.push Solargraph::Pin::InstanceVariable.new(self, c, fqn || '', local_scope)
                  pins.push Solargraph::Pin::InstanceVariable.new(get_node_location(c), fqn || '',c.children[0].to_s, docstring_for(c), local_scope)
                end
              elsif c.type == :cvasgn
                if c.children[1].nil?
                  ora = find_parent(stack, :or_asgn)
                  unless ora.nil?
                    u = c.updated(:cvasgn, c.children + ora.children[1..-1], nil)
                    @node_tree[u.object_id] = @node_stack.clone
                    # @all_nodes.push u
                    @docstring_hash[u.loc] = docstring_for(ora)
                    # class_variable_pins.push Solargraph::Pin::ClassVariable.new(self, u, fqn || '')
                    pins.push Solargraph::Pin::ClassVariable.new(get_node_location(u), fqn || '', c.children[0].to_s, docstring_for(u))
                  end
                else
                  # class_variable_pins.push Solargraph::Pin::ClassVariable.new(self, c, fqn || '')
                  pins.push Solargraph::Pin::ClassVariable.new(get_node_location(c), fqn || '', c.children[0].to_s, docstring_for(c), code_for(c.children[1]), resolve_node_signature(c.children[1]))
                end
              elsif c.type == :lvasgn
                if c.children[1].nil?
                  ora = find_parent(stack, :or_asgn)
                  unless ora.nil?
                    u = c.updated(:lvasgn, c.children + ora.children[1..-1], nil)
                    # @all_nodes.push u
                    @node_tree[u] = @node_stack.clone
                    @docstring_hash[u.loc] = docstring_for(ora)
                    # local_variable_pins.push Solargraph::Pin::LocalVariable.new(self, u, fqn || '', @node_stack.clone)
                    @locals.push Solargraph::Pin::LocalVariable.new(get_node_location(u), fqn, u.children[0].to_s, docstring_for(u), resolve_node_signature(c.children[1]), infer_literal_node_type(c.children[1]))
                  end
                else
                  # @node_tree[c] = @node_stack.clone
                  # local_variable_pins.push Solargraph::Pin::LocalVariable.new(self, c, fqn || '', @node_stack.clone)
                  @locals.push Solargraph::Pin::LocalVariable.new(get_node_location(c), fqn, c.children[0].to_s, docstring_for(c), resolve_node_signature(c.children[1]), infer_literal_node_type(c.children[1]))
                end
              elsif c.type == :gvasgn
                # global_variable_pins.push Solargraph::Pin::GlobalVariable.new(self, c, fqn || '')
                pins.push Solargraph::Pin::GlobalVariable.new(get_node_location(c), fqn, c.children[0].to_s, docstring_for(c), resolve_node_signature(c.children[1]), infer_literal_node_type(c.children[1]))
              elsif c.type == :sym
                # symbol_pins.push Solargraph::Pin::Symbol.new(self, c, fqn)
                @symbols.push Solargraph::Pin::Symbol.new(get_node_location(c), ":#{c.children[0]}")

              elsif c.type == :casgn
                # constant_pins.push Solargraph::Pin::Constant.new(self, c, fqn, :public)
                # pins.push Solargraph::Pin::Constant.new(self, c, fqn, :public)
                pins.push Solargraph::Pin::Constant.new(get_node_location(c), fqn, c.children[1].to_s, docstring_for(c), resolve_node_signature(c.children[2]), infer_literal_node(c.children[2]), :public)
              elsif c.type == :def and c.children[0].to_s[0].match(/[a-z]/i)
                # method_pin_map[fqn || ''] ||= []
                # method_pin_map[fqn || ''].push Solargraph::Pin::Method.new(source, c, fqn || '', scope, visibility)
                pins.push Solargraph::Pin::Method.new(get_node_location(c), fqn || '', c.children[(c.type == :def ? 0 : 1)].to_s, docstring_for(c), scope, visibility)
              elsif c.type == :defs
                s_visi = visibility
                s_visi = :public if scope != :class
                if c.children[0].is_a?(AST::Node) and c.children[0].type == :self
                  dfqn = fqn || ''
                else
                  dfqn = unpack_name(c.children[0])
                end
                unless dfqn.nil?
                  # method_pin_map[dfqn] ||= []
                  # method_pin_map[dfqn].push Solargraph::Pin::Method.new(source, c, dfqn, :class, s_visi)
                  # pins.push Solargraph::Pin::Method.new(source, c, dfqn, :class, s_visi)
                  pins.push Solargraph::Pin::Method.new(get_node_location(c), dfqn, "#{c.children[(node.type == :def ? 0 : 1)]}", docstring_for(c), :class, s_visi)
                  process c, tree, scope, :class, dfqn, stack
                end
                next
              elsif c.type == :send and [:public, :protected, :private].include?(c.children[1])
                visibility = c.children[1]
              elsif c.type == :send and [:private_class_method].include?(c.children[1]) and c.children[2].kind_of?(AST::Node)
                if c.children[2].type == :sym or c.children[2].type == :str
                  ref = pins.select{|p| p.namespace == (fqn || '') and p.name == c.children[2].children[0].to_s}.first
                  unless ref.nil?
                    pins.delete ref
                    # method_pin_map[fqn || ''].delete ref
                    # method_pin_map[fqn || ''].push Solargraph::Pin::Method.new(ref.source, ref.node, ref.namespace, ref.scope, :private)
                    # pins.push Solargraph::Pin::Method.new(ref.source, ref.node, ref.namespace, ref.scope, :private)
                    pins.push Solargraph::Pin::Method.new(ref.location, ref.namespace, ref.name, ref.docstring, ref.scope, :private)
                  end
                else
                  process c, tree, :private, :class, fqn, stack
                  next
                end
              elsif c.type == :send and [:private_constant].include?(c.children[1]) and c.children[2].kind_of?(AST::Node)
                if c.children[2].type == :sym or c.children[2].type == :str
                  # @todo What to do about references?
                  cn = c.children[2].children[0].to_s
                  ref = pins.select{|p| p.namespace == (fqn || '') and p.name == cn}.first
                  unless ref.nil?
                    pins.delete ref
                    pins.push ref.class.new(ref.location, ref.namespace, ref.name, :private)
                  end
                end
                next
              elsif c.type == :send and c.children[1] == :include and c.children[0].nil?
                # @todo What to do about references?
                # if @node_tree[0].nil? or @node_tree[0].type == :source or @node_tree[0].type == :class or @node_tree[0].type == :module or (@node_tree.length > 1 and @node_tree[0].type == :begin and (@node_tree[1].type == :class or @node_tree[1].type == :module))
                #   if c.children[2].kind_of?(AST::Node) and c.children[2].type == :const
                #     c.children[2..-1].each do |i|
                #       namespace_pins(fqn || '').last.reference_include unpack_name(i)
                #     end
                #   end
                # end
              elsif c.type == :send and c.children[1] == :extend and c.children[0].nil?
                # @todo What to do about references?
                # if @node_tree[0].nil? or @node_tree[0].type == :source or @node_tree[0].type == :class or @node_tree[0].type == :module or (@node_tree.length > 1 and @node_tree[0].type == :begin and (@node_tree[1].type == :class or @node_tree[1].type == :module))
                #   if c.children[2].kind_of?(AST::Node) and c.children[2].type == :const
                #     # namespace_extends[fqn || ''] ||= []
                #     c.children[2..-1].each do |i|
                #       namespace_pin_map[fqn || ''].last.reference_extend unpack_name(i)
                #     end
                #   end
                # end
              elsif c.type == :send and [:attr_reader, :attr_writer, :attr_accessor].include?(c.children[1])
                c.children[2..-1].each do |a|
                  if c.children[1] == :attr_reader or c.children[1] == :attr_accessor
                    # attribute_pins.push Solargraph::Pin::Attribute.new(self, a, fqn || '', :reader, docstring_for(c)) #AttrPin.new(c)
                    # pins.push Solargraph::Pin::Attribute.new(self, a, fqn || '', :reader, docstring_for(c)) #AttrPin.new(c)
                    pins.push Solargraph::Pin::Attribute.new(get_node_location(c), fqn || '', "#{c.children[0]}", docstring_for(c), :reader) #AttrPin.new(c)
                  end
                  if c.children[1] == :attr_writer or c.children[1] == :attr_accessor
                    # attribute_pins.push Solargraph::Pin::Attribute.new(self, a, fqn || '', :writer, docstring_for(c)) #AttrPin.new(c)
                    # pins.push Solargraph::Pin::Attribute.new(self, a, fqn || '', :writer, docstring_for(c)) #AttrPin.new(c)
                    pins.push Solargraph::Pin::Attribute.new(get_node_location(c), fqn || '', "#{c.children[0]}=", docstring_for(c), :writer) #AttrPin.new(c)
                  end
                end
              elsif c.type == :sclass and c.children[0].type == :self
                process c, tree, :public, :class, fqn || '', stack
                next
              elsif c.type == :send and c.children[1] == :require
                if c.children[2].kind_of?(AST::Node) and c.children[2].type == :str
                  # @todo Need a require array?
                  @requires.push c.children[2].children[0].to_s
                end
              elsif c.type == :args
                if @node_stack.first.type == :block
                  pi = 0
                  c.children.each do |u|
                    # @todo Fix this
                    # pins.push Solargraph::Pin::BlockParameter.new(self, u, fqn || '', @node_stack.clone, pi)
                    pi += 1
                  end
                else
                  c.children.each do |u|
                    # @todo Fix this
                    # pins.push Solargraph::Pin::MethodParameter.new(self, u, fqn || '', @node_stack.clone)
                  end
                end
              end
              process c, tree, visibility, scope, fqn, stack
            end
          end
          @node_stack.shift
        end
        stack.pop
      end

      # @return [YARD::Docstring]
      def docstring_for node
        return @docstring_hash[node.loc] if node.respond_to?(:loc)
        nil
      end

      def get_node_location(node)
        st = Position.new(node.loc.line - 1, node.loc.column)
        en = Position.new(node.loc.last_line - 1, node.loc.last_column)
        range = Range.new(st, en)
        Location.new(filename, range)
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
    end
  end
end
