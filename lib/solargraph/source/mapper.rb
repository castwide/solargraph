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
        # @node_tree = []
        @comment_hash = {}
        @directives = {}
        @docstring_hash = associate_comments(node, comments)
        # @todo Stuff that needs to be resolved
        @variables = []
        @path_macros = {}

        @pins = []
        @requires = []
        @symbols = []
        @locals = []

        # HACK make sure the first node gets processed
        root = AST::Node.new(:source, [filename])
        root = root.append node
        # @todo Is the root namespace a class or a module? Assuming class for now.
        @pins.push Pin::Namespace.new(get_node_location(nil), '', '', nil, :class, :public, nil)
        process root
        process_directives
        [@pins, @locals, @requires, @symbols, @path_macros]
      end

      class << self
        # @return [Array<Solargraph::Pin::Base>]
        def map filename, code, node, comments
          new.map filename, code, node, comments
        end
      end

      # @param node [Parser::AST::Node]
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
            pins.push Solargraph::Pin::Namespace.new(get_node_location(node), tree[0..-2].join('::') || '', pack_name(node.children[0]).last.to_s, docstring_for(node), node.type, visibility, sc)
          end
          file = filename
          node.children.each do |c|
            if c.kind_of?(AST::Node)
              if c.type == :ivasgn
                par = find_parent(stack, :class, :module, :def, :defs)
                local_scope = ( (par.kind_of?(AST::Node) and par.type == :def) ? :instance : :class )
                if c.children[1].nil?
                  ora = find_parent(stack, :or_asgn)
                  unless ora.nil?
                    u = c.updated(:ivasgn, c.children + ora.children[1..-1], nil)
                    @docstring_hash[u.loc] = docstring_for(ora)
                    pins.push Solargraph::Pin::InstanceVariable.new(get_node_location(u), fqn || '', c.children[0].to_s, docstring_for(u), resolve_node_signature(u.children[1]), infer_literal_node_type(u.children[1]), local_scope)
                  end
                else
                  pins.push Solargraph::Pin::InstanceVariable.new(get_node_location(c), fqn || '',c.children[0].to_s, docstring_for(c), resolve_node_signature(c.children[1]), infer_literal_node_type(c.children[1]), local_scope)
                end
              elsif c.type == :cvasgn
                if c.children[1].nil?
                  ora = find_parent(stack, :or_asgn)
                  unless ora.nil?
                    u = c.updated(:cvasgn, c.children + ora.children[1..-1], nil)
                    @docstring_hash[u.loc] = docstring_for(ora)
                    pins.push Solargraph::Pin::ClassVariable.new(get_node_location(u), fqn || '', c.children[0].to_s, docstring_for(u), resolve_node_signature(u.children[1]), infer_literal_node_type(u.children[1]))
                  end
                else
                  pins.push Solargraph::Pin::ClassVariable.new(get_node_location(c), fqn || '', c.children[0].to_s, docstring_for(c), resolve_node_signature(c.children[1]), infer_literal_node_type(c.children[1]))
                end
              elsif c.type == :lvasgn
                here = get_node_start_position(c)
                block = get_block_pin(here)
                presence = Source::Range.new(here, block.location.range.ending)
                if c.children[1].nil?
                  ora = find_parent(stack, :or_asgn)
                  unless ora.nil?
                    u = c.updated(:lvasgn, c.children + ora.children[1..-1], nil)
                    @docstring_hash[u.loc] = docstring_for(ora)
                    @locals.push Solargraph::Pin::LocalVariable.new(get_node_location(u), fqn, u.children[0].to_s, docstring_for(u), resolve_node_signature(c.children[1]), infer_literal_node_type(c.children[1]), block, presence)
                  end
                else
                  @locals.push Solargraph::Pin::LocalVariable.new(get_node_location(c), fqn, c.children[0].to_s, docstring_for(c), resolve_node_signature(c.children[1]), infer_literal_node_type(c.children[1]), block, presence)
                end
              elsif c.type == :gvasgn
                pins.push Solargraph::Pin::GlobalVariable.new(get_node_location(c), fqn, c.children[0].to_s, docstring_for(c), resolve_node_signature(c.children[1]), infer_literal_node_type(c.children[1]))
              elsif c.type == :sym
                @symbols.push Solargraph::Pin::Symbol.new(get_node_location(c), ":#{c.children[0]}")

              elsif c.type == :casgn
                pins.push Solargraph::Pin::Constant.new(get_node_location(c), fqn, c.children[1].to_s, docstring_for(c), resolve_node_signature(c.children[2]), infer_literal_node_type(c.children[2]), :public)
              elsif c.type == :def and c.children[0].to_s[0].match(/[a-z]/i)
               methpin = Solargraph::Pin::Method.new(get_node_location(c), fqn || '', c.children[(c.type == :def ? 0 : 1)].to_s, docstring_for(c), scope, visibility, get_method_args(c))
               if methpin.name == 'initialize' and methpin.scope == :instance
                pins.push Solargraph::Pin::Method.new(methpin.location, methpin.namespace, methpin.name, methpin.docstring, methpin.scope, :private, methpin.parameters)
                pins.push Solargraph::Pin::Method.new(methpin.location, methpin.namespace, 'new', methpin.docstring, :class, :public, methpin.parameters)
               else
                pins.push methpin
               end
              elsif c.type == :defs
                s_visi = visibility
                s_visi = :public if scope != :class
                if c.children[0].is_a?(AST::Node) and c.children[0].type == :self
                  dfqn = fqn || ''
                else
                  dfqn = unpack_name(c.children[0])
                end
                unless dfqn.nil?
                  pins.push Solargraph::Pin::Method.new(get_node_location(c), dfqn, "#{c.children[(node.type == :def ? 0 : 1)]}", docstring_for(c), :class, s_visi, get_method_args(c))
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
                    pins.push Solargraph::Pin::Method.new(ref.location, ref.namespace, ref.name, ref.docstring, ref.scope, :private, ref.parameters)
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
                    # Might be either a namespace or constant
                    if ref.kind == Pin::CONSTANT
                      pins.push ref.class.new(ref.location, ref.namespace, ref.name, ref.docstring, ref.signature, ref.return_type, :private)
                    else
                      pins.push ref.class.new(ref.location, ref.namespace, ref.name, ref.docstring, ref.type, :private, (ref.superclass_reference.nil? ? nil : ref.superclass_reference.name))
                    end
                  end
                end
                next
              elsif c.type == :send and c.children[1] == :include and c.children[0].nil?
                last_node = get_last_in_stack_not_begin(stack)
                if last_node.nil? or last_node.type == :class or last_node.type == :module or last_node.type == :source
                  if c.children[2].kind_of?(AST::Node) and c.children[2].type == :const
                    c.children[2..-1].each do |i|
                      nspin = @pins.select{|pin| pin.kind == Pin::NAMESPACE and pin.path == fqn}.last
                      unless nspin.nil?
                        iref = Pin::Reference.new(get_node_location(c), nspin.path, unpack_name(i))
                        nspin.include_references.push(iref)
                      end
                    end
                  end
                end
              elsif c.type == :send and c.children[1] == :extend and c.children[0].nil?
                last_node = get_last_in_stack_not_begin(stack)
                if last_node.nil? or last_node.type == :class or last_node.type == :module or last_node.type == :source
                  if c.children[2].kind_of?(AST::Node) and c.children[2].type == :const
                    # namespace_extends[fqn || ''] ||= []
                    c.children[2..-1].each do |i|
                      nspin = @pins.select{|pin| pin.kind == Pin::NAMESPACE and pin.path == fqn}.last
                      unless nspin.nil?
                        ref = Pin::Reference.new(get_node_location(c), nspin.path, unpack_name(i))
                        nspin.extend_references.push(ref)
                      end
                    end
                  end
                end
              elsif c.type == :send and [:attr_reader, :attr_writer, :attr_accessor].include?(c.children[1])
                c.children[2..-1].each do |a|
                  if c.children[1] == :attr_reader or c.children[1] == :attr_accessor
                    pins.push Solargraph::Pin::Attribute.new(get_node_location(c), fqn || '', "#{a.children[0]}", docstring_for(c), :reader) #AttrPin.new(c)
                  end
                  if c.children[1] == :attr_writer or c.children[1] == :attr_accessor
                    pins.push Solargraph::Pin::Attribute.new(get_node_location(c), fqn || '', "#{a.children[0]}=", docstring_for(c), :writer) #AttrPin.new(c)
                  end
                end
              elsif c.type == :sclass and c.children[0].type == :self
                process c, tree, :public, :class, fqn || '', stack
                next
              elsif c.type == :send and c.children[1] == :require
                if c.children[2].kind_of?(AST::Node) and c.children[2].type == :str
                  @requires.push c.children[2].children[0].to_s
                end
              elsif c.type == :args
                if @node_stack.first.type == :block
                  pi = 0
                  c.children.each do |u|
                    # @todo Fix this
                    # pins.push Solargraph::Pin::BlockParameter.new(self, u, fqn || '', @node_stack.clone, pi)
                    here = get_node_start_position(c)
                    blk = get_block_pin(here)
                    @locals.push Solargraph::Pin::BlockParameter.new(get_node_location(u), fqn || '', "#{u.children[0]}", docstring_for(c), blk)
                    blk.parameters.push @locals.push.last
                    pi += 1
                  end
                else
                  c.children.each do |u|
                    here = get_node_start_position(c)
                    blk = get_block_pin(here)
                    @locals.push Solargraph::Pin::MethodParameter.new(get_node_location(u), fqn || '', "#{u.children[0]}", docstring_for(c), blk)
                  end
                end
              elsif c.type == :block
                @pins.push Solargraph::Pin::Block.new(get_node_location(c), fqn || '', '', docstring_for(c), resolve_node_signature(c.children[0]))
              end
              process c, tree, visibility, scope, fqn, stack
            end
          end
          @node_stack.shift
        end
        stack.pop
      end

      # def path_for node
      #   path = namespace_for(node) || ''
      #   mp = (method_pins + attribute_pins).select{|p| p.node == node}.first
      #   unless mp.nil?
      #     path += (mp.scope == :instance ? '#' : '.') + mp.name
      #   end
      #   path
      # end
  
      def get_last_in_stack_not_begin stack
        index = stack.length - 1
        last = stack[index]
        while !last.nil? and last.type == :begin
          index -= 1
          last = stack[index]
        end
        last
      end

      def get_block_pin position
        @pins.select{|pin| [Pin::BLOCK, Pin::NAMESPACE, Pin::METHOD].include?(pin.kind) and pin.location.range.contain?(position)}.last
      end

      # @return [YARD::Docstring]
      def docstring_for node
        return @docstring_hash[node.loc] if node.respond_to?(:loc)
        nil
      end

      def get_node_start_position(node)
        Position.new(node.loc.line - 1, node.loc.column)
      end

      def get_node_location(node)
        if node.nil?
          st = Position.new(0, 0)
          en = Position.from_offset(@code, @code.length)
        else
          st = Position.new(node.loc.line - 1, node.loc.column)
          en = Position.new(node.loc.last_line - 1, node.loc.last_column)
        end
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

      def namespace_for(node)
        position = Source::Position.new(node.loc.line - 1, node.loc.column)
        @pins.select{|pin| pin.kind == Pin::NAMESPACE and pin.location.range.contain?(position)}.last
      end

      def process_directives
        @directives.each_pair do |k, v|
          v.each do |d|
            ns = namespace_for(k.node)
            docstring = YARD::Docstring.parser.parse(d.tag.text).to_docstring
            if d.tag.tag_name == 'attribute'
              t = (d.tag.types.nil? || d.tag.types.empty?) ? nil : d.tag.types.flatten.join('')
              if t.nil? or t.include?('r')
                # location, namespace, name, docstring, access
                pins.push Solargraph::Pin::Attribute.new(get_node_location(k.node), namespace_for(k.node).path, d.tag.name, docstring, :reader)
              end
              if t.nil? or t.include?('w')
                pins.push Solargraph::Pin::Attribute.new(get_node_location(k.node), namespace_for(k.node).path, "#{d.tag.name}=", docstring, :reader)
              end
            elsif d.tag.tag_name == 'method'
              gen_src = Source.new("def #{d.tag.name};end", filename)
              gen_pin = gen_src.pins.last # Method is last pin after root namespace
              nsp = namespace_for(k.node)
              next if nsp.nil? # @todo Add methods to global namespace?
              @pins.push Solargraph::Pin::Method.new(get_node_location(k.node), nsp.path, gen_pin.name, docstring, :instance, :public, [])
            elsif d.tag.tag_name == 'macro'
              # @todo Handle various types of macros (attach, new, whatever)
              # path = path_for(k.node)
              here = get_node_start_position(k.node)
              pin = @pins.select{|pin| [Pin::NAMESPACE, Pin::METHOD].include?(pin.kind) and pin.location.range.contain?(here)}.first
              @path_macros[pin.path] = v
            else
              # STDERR.puts "Nothing to do for directive: #{d}"
            end
          end
        end
      end

      def find_parent(stack, *types)
        stack.reverse.each { |p|
          return p if types.include?(p.type)
        }
        nil
      end

      def get_method_args node
        return [] if node.nil?
        list = nil
        args = []
        node.children.each { |c|
          if c.kind_of?(AST::Node) and c.type == :args
            list = c
            break
          end
        }
        return args if list.nil?
        list.children.each { |c|
          if c.type == :arg
            args.push c.children[0].to_s
          elsif c.type == :restarg
            args.push "*#{c.children[0]}"
          elsif c.type == :optarg
            args.push "#{c.children[0]} = #{code_for(c.children[1])}"
          elsif c.type == :kwarg
            args.push "#{c.children[0]}:"
          elsif c.type == :kwoptarg
            args.push "#{c.children[0]}: #{code_for(c.children[1])}"
          elsif c.type == :blockarg
            args.push "&#{c.children[0]}"
          end
        }
        args
      end
    end
  end
end
