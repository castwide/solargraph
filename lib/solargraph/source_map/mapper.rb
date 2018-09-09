module Solargraph
  class SourceMap
    # The Mapper generates pins and other data for SourceMaps.
    #
    # This class is used internally by the SourceMap class. Users should not
    # normally need to call it directly.
    #
    class Mapper
      include Source::NodeMethods

      private_class_method :new

      # Generate the data.
      #
      # @return [Array]
      def map filename, code, node, comments
        @filename = filename
        @code = code
        @node = node
        @comments = comments
        @node_stack = []
        @directives = {}
        @comment_ranges = comments.map do |c|
          Range.from_to(c.loc.expression.line, c.loc.expression.column, c.loc.expression.last_line, c.loc.expression.last_column)
        end
        @node_comments = associate_comments(node, comments)
        @pins = []
        @requires = []
        @symbols = []
        @locals = []
        @strings = []

        # HACK make sure the first node gets processed
        root = AST::Node.new(:source, [filename])
        root = root.append node
        # @todo Is the root namespace a class or a module? Assuming class for now.
        @pins.push Pin::Namespace.new(get_node_location(nil), '', '', nil, :class, :public, nil)
        process root
        # @node_comments.each do |k, v|
        #   # @pins.first.comments.concat v
        #   if v.include?('@!')
        #     ns = namespace_at(Position.new(k.expression.line, k.expression.column))
        #     loc = Location.new(filename, Range.from_to(k.expression.line, k.expression.column, k.expression.last_line, k.expression.last_column))
        #     process_directive ns, loc, v
        #   end
        # end
        process_comment_directives
        [@pins, @locals, @requires, @symbols]
      end

      def unmap filename, code
        s = Position.new(0, 0)
        e = Position.from_offset(code, code.length)
        location = Location.new(filename, Range.new(s, e))
        [[Pin::Namespace.new(location, '', '', '', :class, :public, nil)], [], [], []]
      end

      class << self
        # @param source [Source]
        # @return [Array]
        def map source
          return new.unmap(source.filename, source.code) unless source.parsed?
          new.map source.filename, source.code, source.node, source.comments
        end
      end

      # @param node [Parser::AST::Node]
      # @return [String]
      def code_for node
        # @todo Using node locations on code with converted EOLs seems
        #   slightly more efficient than calculating offsets.
        b = node.location.expression.begin.begin_pos
        e = node.location.expression.end.end_pos
        # b = Position.line_char_to_offset(@code, node.location.line - 1, node.location.column)
        # e = Position.line_char_to_offset(@code, node.location.last_line - 1, node.location.last_column)
        frag = source_from_parser[b..e-1].to_s
        frag.strip.gsub(/,$/, '')
      end

      # @return [String]
      def filename
        @filename
      end

      # @return [Array<Solargraph::Pin::Base>]
      def pins
        @pins ||= []
      end

      # @param node [Parser::AST::Node]
      def process node, tree = [], visibility = :public, scope = :instance, fqn = '', stack = []
        return unless node.is_a?(AST::Node)
        return if node.type == :str
        stack.push node
        if node.kind_of?(AST::Node)
          @node_stack.unshift node
          if node.type == :class or node.type == :module
            visibility = :public
            if node.children[0].kind_of?(AST::Node) and node.children[0].children[0].kind_of?(AST::Node) and node.children[0].children[0].type == :cbase
              tree = pack_name(node.children[0])
              tree.shift if tree.first.empty?
            else
              tree = tree + pack_name(node.children[0])
            end
            fqn = tree.join('::')
            sc = nil
            if node.type == :class and !node.children[1].nil?
              sc = unpack_name(node.children[1])
            end
            pins.push Solargraph::Pin::Namespace.new(get_node_location(node), tree[0..-2].join('::') || '', pack_name(node.children[0]).last.to_s, comments_for(node), node.type, visibility, sc)
          end
          file = filename
          node.children.each do |c|
            if c.kind_of?(AST::Node)
              if c.type == :ivasgn
                here = get_node_start_position(c)
                named_path = get_named_path_pin(here)
                if c.children[1].nil?
                  ora = find_parent(stack, :or_asgn)
                  unless ora.nil?
                    u = c.updated(:ivasgn, c.children + ora.children[1..-1], nil)
                    pins.push Solargraph::Pin::InstanceVariable.new(get_node_location(u), fqn || '', c.children[0].to_s, comments_for(u), u.children[1], infer_literal_node_type(u.children[1]), named_path.context)
                    if visibility == :module_function and named_path.kind == Pin::METHOD
                      other = ComplexType.parse("Module<#{named_path.context.namespace}>")
                      pins.push Solargraph::Pin::InstanceVariable.new(get_node_location(u), fqn || '', c.children[0].to_s, comments_for(u), u.children[1], infer_literal_node_type(u.children[1]), other) #unless other.nil?
                    end
                  end
                else
                  pins.push Solargraph::Pin::InstanceVariable.new(get_node_location(c), fqn || '',c.children[0].to_s, comments_for(c), c.children[1], infer_literal_node_type(c.children[1]), named_path.context)
                  if visibility == :module_function and named_path.kind == Pin::METHOD
                    other = ComplexType.parse("Module<#{named_path.context.namespace}>")
                     pins.push Solargraph::Pin::InstanceVariable.new(get_node_location(c), fqn || '',c.children[0].to_s, comments_for(c), c.children[1], infer_literal_node_type(c.children[1]), other)
                  end
                end
              elsif c.type == :cvasgn
                here = get_node_start_position(c)
                context = get_named_path_pin(here)
                if c.children[1].nil?
                  ora = find_parent(stack, :or_asgn)
                  unless ora.nil?
                    u = c.updated(:cvasgn, c.children + ora.children[1..-1], nil)
                    pins.push Solargraph::Pin::ClassVariable.new(get_node_location(u), fqn || '', c.children[0].to_s, comments_for(u), u.children[1], infer_literal_node_type(u.children[1]), context)
                  end
                else
                  pins.push Solargraph::Pin::ClassVariable.new(get_node_location(c), fqn || '', c.children[0].to_s, comments_for(c), c.children[1], infer_literal_node_type(c.children[1]), context)
                end
              elsif c.type == :lvasgn
                here = get_node_start_position(c)
                context = get_named_path_pin(here)
                block = get_block_pin(here)
                presence = Range.new(here, block.location.range.ending)
                if c.children[1].nil?
                  ora = find_parent(stack, :or_asgn)
                  unless ora.nil?
                    u = c.updated(:lvasgn, c.children + ora.children[1..-1], nil)
                    @locals.push Solargraph::Pin::LocalVariable.new(get_node_location(u), fqn, u.children[0].to_s, comments_for(ora), u.children[1], infer_literal_node_type(c.children[1]), context, block, presence)
                  end
                else
                  @locals.push Solargraph::Pin::LocalVariable.new(get_node_location(c), fqn, c.children[0].to_s, comments_for(c), c.children[1], infer_literal_node_type(c.children[1]), context, block, presence)
                end
              elsif c.type == :gvasgn
                if c.children[1].nil?
                  ora = find_parent(stack, :or_asgn)
                  unless ora.nil?
                    u = c.updated(:gvasgn, c.children + ora.children[1..-1], nil)
                    pins.push Solargraph::Pin::GlobalVariable.new(get_node_location(c), fqn, u.children[0].to_s, comments_for(c), u.children[1], infer_literal_node_type(c.children[1]), @pins.first)
                  end
                else
                  pins.push Solargraph::Pin::GlobalVariable.new(get_node_location(c), fqn, c.children[0].to_s, comments_for(c), c.children[1], infer_literal_node_type(c.children[1]), @pins.first)
                end
              elsif c.type == :sym
                @symbols.push Solargraph::Pin::Symbol.new(get_node_location(c), ":#{c.children[0]}")
              elsif c.type == :casgn
                here = get_node_start_position(c)
                block = get_block_pin(here)
                pins.push Solargraph::Pin::Constant.new(get_node_location(c), fqn, c.children[1].to_s, comments_for(c), c.children[2], infer_literal_node_type(c.children[2]), block, :public)
              elsif c.type == :def
                methpin = Solargraph::Pin::Method.new(get_node_location(c), fqn || '', c.children[(c.type == :def ? 0 : 1)].to_s, comments_for(c), scope, visibility, get_method_args(c))
                if methpin.name == 'initialize' and methpin.scope == :instance
                  pins.push Solargraph::Pin::Method.new(methpin.location, methpin.namespace, 'new', methpin.comments, :class, :public, methpin.parameters)
                  # @todo Smelly instance variable access.
                  pins.last.instance_variable_set(:@return_complex_type, ComplexType.parse(methpin.namespace))
                  pins.push Solargraph::Pin::Method.new(methpin.location, methpin.namespace, methpin.name, methpin.comments, methpin.scope, :private, methpin.parameters)
                elsif visibility == :module_function
                  pins.push Solargraph::Pin::Method.new(methpin.location, methpin.namespace, methpin.name, methpin.comments, :class, :public, methpin.parameters)
                  pins.push Solargraph::Pin::Method.new(methpin.location, methpin.namespace, methpin.name, methpin.comments, :instance, :private, methpin.parameters)
                else
                  pins.push methpin
                end
              elsif c.type == :defs
                s_visi = visibility
                s_visi = :public if s_visi == :module_function or scope != :class
                if c.children[0].is_a?(AST::Node) and c.children[0].type == :self
                  dfqn = fqn || ''
                else
                  dfqn = unpack_name(c.children[0])
                end
                unless dfqn.nil?
                  pins.push Solargraph::Pin::Method.new(get_node_location(c), dfqn, "#{c.children[(node.type == :def ? 0 : 1)]}", comments_for(c), :class, s_visi, get_method_args(c))
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
                    pins.push Solargraph::Pin::Method.new(ref.location, ref.namespace, ref.name, ref.comments, ref.scope, :private, ref.parameters)
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
                      pins.push ref.class.new(ref.location, ref.namespace, ref.name, ref.comments, ref.signature, ref.return_type, ref.context, :private)
                    else
                      pins.push ref.class.new(ref.location, ref.namespace, ref.name, ref.comments, ref.type, :private, (ref.superclass_reference.nil? ? nil : ref.superclass_reference.name))
                    end
                  end
                end
                next
              elsif c.type == :send and c.children[1] == :module_function
                if c.children[2].nil?
                  visibility = :module_function
                elsif c.children[2].type == :sym or c.children[2].type == :str
                  # @todo What to do about references?
                  c.children[2..-1].each do |x|
                    cn = x.children[0].to_s
                    ref = pins.select{|p| p.namespace == (fqn || '') and p.name == cn}.first
                    unless ref.nil?
                      pins.delete ref
                      mm = Solargraph::Pin::Method.new(ref.location, ref.namespace, ref.name, ref.comments, :class, :public, ref.parameters)
                      cm = Solargraph::Pin::Method.new(ref.location, ref.namespace, ref.name, ref.comments, :instance, :private, ref.parameters)
                      pins.push mm, cm
                      pins.select{|pin| pin.kind == Pin::INSTANCE_VARIABLE and pin.context == ref.context}.each do |ivar|
                        pins.delete ivar
                        pins.push Solargraph::Pin::InstanceVariable.new(ivar.location, ivar.namespace, ivar.name, ivar.comments, ivar.signature, ivar.instance_variable_get(:@literal), mm)
                        pins.push Solargraph::Pin::InstanceVariable.new(ivar.location, ivar.namespace, ivar.name, ivar.comments, ivar.signature, ivar.instance_variable_get(:@literal), cm)
                      end
                    end
                  end
                elsif c.children[2].type == :def
                  # @todo A single function
                  process c, tree, :module_function, :class, fqn, stack
                  next
                end
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
                  c.children[2..-1].each do |i|
                    nspin = @pins.select{|pin| pin.kind == Pin::NAMESPACE and pin.path == fqn}.last
                    unless nspin.nil?
                      ref = nil
                      if i.type == :self
                        ref = Pin::Reference.new(get_node_location(c), nspin.path, nspin.path)
                      elsif i.type == :const
                        ref = Pin::Reference.new(get_node_location(c), nspin.path, unpack_name(i))
                      end
                      nspin.extend_references.push(ref) unless ref.nil?
                    end
                  end
                end
              elsif c.type == :send and [:attr_reader, :attr_writer, :attr_accessor].include?(c.children[1])
                c.children[2..-1].each do |a|
                  if c.children[1] == :attr_reader or c.children[1] == :attr_accessor
                    pins.push Solargraph::Pin::Attribute.new(get_node_location(c), fqn || '', "#{a.children[0]}", comments_for(c), :reader, scope, visibility)
                  end
                  if c.children[1] == :attr_writer or c.children[1] == :attr_accessor
                    pins.push Solargraph::Pin::Attribute.new(get_node_location(c), fqn || '', "#{a.children[0]}=", comments_for(c), :writer, scope, visibility)
                  end
                end
              elsif c.type == :sclass and c.children[0].type == :self
                process c, tree, :public, :class, fqn || '', stack
                next
              elsif c.type == :send and c.children[1] == :require
                if c.children[2].kind_of?(AST::Node) and c.children[2].type == :str
                  @requires.push Solargraph::Pin::Reference.new(get_node_location(c), fqn, c.children[2].children[0].to_s)
                end
              elsif c.type == :args
                if @node_stack.first.type == :block
                  pi = 0
                  c.children.each do |u|
                    here = get_node_start_position(c)
                    blk = get_block_pin(here)
                    @locals.push Solargraph::Pin::BlockParameter.new(get_node_location(u), fqn || '', "#{u.children[0]}", comments_for(c), blk)
                    blk.parameters.push @locals.push.last
                    pi += 1
                  end
                else
                  c.children.each do |u|
                    here = get_node_start_position(u)
                    context = get_named_path_pin(here)
                    block = get_block_pin(here)
                    presence = Range.new(here, block.location.range.ending)
                    @locals.push Solargraph::Pin::MethodParameter.new(get_node_location(u), fqn, u.children[0].to_s, comments_for(c), resolve_node_signature(u.children[1]), infer_literal_node_type(u.children[1]), context, block, presence)
                  end
                end
              elsif c.type == :block
                here = get_node_start_position(c)
                named_path = get_named_path_pin(here)
                @pins.push Solargraph::Pin::Block.new(get_node_location(c), fqn || '', '', comments_for(c), c.children[0], named_path.context)
              end
              process c, tree, visibility, scope, fqn, stack
            end
          end
          @node_stack.shift
        end
        stack.pop
      end

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

      def get_named_path_pin position
        @pins.select{|pin| [Pin::NAMESPACE, Pin::METHOD].include?(pin.kind) and pin.location.range.contain?(position)}.last
      end

      def get_namespace_pin position
        @pins.select{|pin| pin.kind == Pin::NAMESPACE and pin.location.range.contain?(position)}.last
      end

      # @return [String]
      def comments_for node
        result = @node_comments[node.loc]
        return nil if result.nil?
        result
      end

      # @param node [Parser::AST::Node]
      # @return [Solargraph::Location]
      def get_node_location(node)
        if node.nil?
          st = Position.new(0, 0)
          en = Position.from_offset(@code, @code.length)
        else
          st = Position.new(node.loc.line, node.loc.column)
          en = Position.new(node.loc.last_line, node.loc.last_column)
        end
        range = Range.new(st, en)
        Location.new(filename, range)
      end

      # @param node [Parser::AST::Node]
      # @param comments [Array]
      # @return [Hash]
      def associate_comments node, comments
        return nil if comments.nil?
        comment_hash = Parser::Source::Comment.associate_locations(node, comments)
        result_hash = {}
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
            ctxt += "#{p[num..-1]}\n" if started
          }
          result_hash[k] = ctxt
        }
        result_hash
      end

      # @param node [Parser::AST::Node]
      # @return [Solargraph::Pin::Namespace]
      def namespace_for(node)
        position = Position.new(node.loc.line, node.loc.column)
        namespace_at(position)
      end

      def namespace_at(position)
        @pins.select{|pin| pin.kind == Pin::NAMESPACE and pin.location.range.contain?(position)}.last
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

      def source_from_parser
        @source_from_parser ||= @code.gsub(/\r\n/, "\n")
      end

      def process_comment position, comment
        cmnt = remove_inline_comment_hashes(comment)
        return unless cmnt =~ /(@\!method|@\!attribute|@\!domain|@\!macro)/
        parse = YARD::Docstring.parser.parse(cmnt)
        parse.directives.each { |d| process_directive(position, d) }
      end

      # @param position [Position]
      # @param directive [YARD::Tags::Directive]
      def process_directive position, directive
        docstring = YARD::Docstring.parser.parse(directive.tag.text).to_docstring
        location = Location.new(@filename, Range.new(position, position))
        case directive.tag.tag_name
        when 'method'
          namespace = namespace_at(position)
          gen_src = Solargraph::SourceMap.load_string("def #{directive.tag.name};end")
          gen_pin = gen_src.pins.last # Method is last pin after root namespace
          @pins.push Solargraph::Pin::Method.new(location, namespace.path, gen_pin.name, docstring.all, :instance, :public, gen_pin.parameters)
        when 'attribute'
          namespace = namespace_at(position)
          t = (directive.tag.types.nil? || directive.tag.types.empty?) ? nil : directive.tag.types.flatten.join('')
          if t.nil? or t.include?('r')
            # location, namespace, name, docstring, access
            pins.push Solargraph::Pin::Attribute.new(location, namespace.path, directive.tag.name, docstring.all, :reader, :instance, :public)
          end
          if t.nil? or t.include?('w')
            pins.push Solargraph::Pin::Attribute.new(location, namespace.path, "#{directive.tag.name}=", docstring.all, :writer, :instance, :public)
          end
        when 'domain'
          namespace = namespace_at(position)
          namespace.domains.push directive.tag.text
        when 'macro'
          nxt_pos = Position.new(position.line + 1, @code.lines[position.line + 1].length)
          path_pin = get_named_path_pin(nxt_pos)
          path_pin.macros.push directive
        end
      end

      def remove_inline_comment_hashes comment
        ctxt = ''
        num = nil
        started = false
        comment.lines.each { |l|
          # Trim the comment and minimum leading whitespace
          p = l.gsub(/^#/, '')
          if num.nil? and !p.strip.empty?
            num = p.index(/[^ ]/)
            started = true
          elsif started and !p.strip.empty?
            cur = p.index(/[^ ]/)
            num = cur if cur < num
          end
          ctxt += "#{p[num..-1]}\n" if started
        }
        ctxt
      end

      def process_comment_directives
        current = []
        last_line = nil
        @comments.each do |cmnt|
          if cmnt.inline?
            if last_line.nil? || cmnt.loc.expression.line == last_line + 1
              if cmnt.loc.expression.column.zero? || @code.lines[cmnt.loc.expression.line][0..cmnt.loc.expression.column-1].strip.empty?
                current.push cmnt
              else
                # @todo Connected to a line of code. Handle separately
              end
            elsif !current.empty?
              process_comment Position.new(current.last.loc.expression.line, current.last.loc.expression.column), current.map(&:text).join("\n")
              current.clear
              current.push cmnt
            end
          else
            # @todo Handle block comments
          end
          last_line = cmnt.loc.expression.line
        end
        unless current.empty?
          process_comment Position.new(current.last.loc.expression.line, current.last.loc.expression.column), current.map(&:text).join("\n")
        end
      end
    end
  end
end
