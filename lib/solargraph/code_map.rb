require 'parser/current'

module Solargraph
  class CodeMap
    # The root node of the parsed code.
    #
    # @return [Parser::AST::Node]
    attr_reader :node

    # The source code being analyzed.
    #
    # @return [String]
    attr_reader :code

    # The source object generated from the code.
    #
    # @return [Solargraph::Source]
    attr_reader :source

    # The filename for the source code.
    #
    # @return [String]
    attr_reader :filename

    include NodeMethods
    include CoreFills

    def initialize code: '', filename: nil, api_map: nil, cursor: nil
      # HACK: Adjust incoming filename's path separator for yardoc file comparisons
      #filename = filename.gsub(File::ALT_SEPARATOR, File::SEPARATOR) unless filename.nil? or File::ALT_SEPARATOR.nil?
      #@filename = filename
      #@api_map = api_map
      if !filename.nil? and filename.end_with?('.erb')
        #@source = self.api_map.virtualize(convert_erb(code), filename, cursor)
        src = Solargraph::Source.fix(convert_erb(code), filename, cursor)
      else
        #@source = self.api_map.virtualize(code, filename, cursor)
        src = Solargraph::Source.fix(code, filename, cursor)
      end
      mix src, filename, api_map
    end

    def mix source, filename, api_map
      @source = source
      @filename = filename
      @api_map = api_map
      @node = source.node
      @code = source.code
      @comments = @source.comments
      self.api_map.append_virtual_source source
      self.api_map.refresh
    end

    def self.from_source source, api_map
      code_map = self.allocate
      code_map.mix source, source.filename, api_map
      code_map
    end

    # Get the associated ApiMap.
    #
    # @return [Solargraph::ApiMap]
    def api_map
      @api_map ||= ApiMap.new(nil)
    end

    # Get the offset of the specified line and column.
    # The offset (also called the "index") is typically used to identify the
    # cursor's location in the code when generating suggestions.
    # The line and column numbers should start at zero.
    #
    # @param line [Integer]
    # @param col [Integer]
    # @return [Integer]
    def get_offset line, col
      CodeMap.get_offset @code, line, col
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

    # Get an array of nodes containing the specified index, starting with the
    # topmost node and ending with the nearest.
    #
    # @param index [Integer]
    # @return [Array<AST::Node>]
    def tree_at(index)
      arr = []
      arr.push @node
      inner_node_at(index, @node, arr)
      arr
    end

    # Get the nearest node that contains the specified index.
    #
    # @param index [Integer]
    # @return [AST::Node]
    def node_at(index)
      tree_at(index).first
    end

    # Determine if the specified index is inside a string.
    #
    # @return [Boolean]
    def string_at?(index)
      n = node_at(index)
      n.kind_of?(AST::Node) and (n.type == :str or n.type == :dstr)
    end

    # Determine if the specified index is inside a comment.
    #
    # @return [Boolean]
    def comment_at?(index)
      return false if string_at?(index)
      line, col = Solargraph::Source.get_position_at(source.code, index)
      return false if source.stubbed_lines.include?(line)
      @comments.each do |c|
        return true if index > c.location.expression.begin_pos and index <= c.location.expression.end_pos
      end
      # Extra test due to some comments not getting tracked
      while (index >= 0 and @code[index] != "\n")
        return false if string_at?(index)
        if @code[index] == '#'
          return true if index == 0
          return false if string_at?(index - 1)
          return true unless @code[index-1, 3] == '"#{'
        end
        index -= 1
      end
      false
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
      @node
    end

    # Get the namespace at the specified location. For example, given the code
    # `class Foo; def bar; end; end`, index 14 (the center) is in the
    # "Foo" namespace.
    #
    # @return [String]
    def namespace_at(index)
      tree = tree_at(index)
      return nil if tree.length == 0
      slice = tree
      parts = []
      slice.reverse.each { |n|
        if n.type == :class or n.type == :module
          c = const_from(n.children[0])
          parts.push c
        end
      }
      parts.join("::")
    end

    # Get the namespace for the specified node. For example, given the code
    # `class Foo; def bar; end; end`, the node for `def bar` is in the "Foo"
    # namespace.
    #
    # @return [String]
    def namespace_from(node)
      if node.respond_to?(:loc)
        namespace_at(node.loc.expression.begin_pos)
      else
        ''
      end
    end

    # Select the word that directly precedes the specified index.
    # A word can only consist of letters, numbers, and underscores.
    #
    # @param index [Integer]
    # @return [String]
    def word_at index
      word = ''
      cursor = index - 1
      while cursor > -1
        char = @code[cursor, 1]
        break if char.nil? or char == ''
        word = char + word if char == '$'
        break unless char.match(/[a-z0-9_]/i)
        word = char + word
        cursor -= 1
      end
      word
    end

    def symbol_range_at index
      cursor = index
      while cursor > -1
        char = @code[cursor - 1, 1]
        break if char.nil? or char == ''
        break unless char.match(/[a-z0-9_@$]/i)
        cursor -= 1
      end
      start_offset = cursor
      cursor = index
      while cursor < @code.length
        char = @code[cursor, 1]
        break if char.nil? or char == ''
        break unless char.match(/[a-z0-9_\?\!]/i)
        cursor += 1
      end
      end_offset = cursor
      end_offset = start_offset if end_offset < start_offset
      start_pos = Solargraph::Source.get_position_at(@code, start_offset)
      end_pos = Solargraph::Source.get_position_at(@code, end_offset)
      {
        start: {
          line: start_pos[0],
          character: start_pos[1]
        },
        end: {
          line: end_pos[0],
          character: end_pos[1]
        }
      }
    end

    def word_range_at index
      cursor = index
      while cursor > -1
        char = @code[cursor - 1, 1]
        break if char.nil? or char == ''
        break unless char.match(/[a-z0-9_]/i)
        cursor -= 1
      end
      start_offset = cursor
      cursor = index
      while cursor < @code.length
        char = @code[cursor + 1, 1]
        break if char.nil? or char == ''
        break unless char.match(/[a-z0-9_]/i)
        cursor += 1
      end
      end_offset = cursor
      end_offset = start_offset if end_offset < start_offset
      start_pos = Solargraph::Source.get_position_at(@code, start_offset)
      end_pos = Solargraph::Source.get_position_at(@code, end_offset)
      {
        start: {
          line: start_pos[0],
          character: start_pos[1]
        },
        end: {
          line: end_pos[0],
          character: end_pos[1]
        }
      }
    end

    # @return [Array<Solargraph::Suggestion>]
    def get_class_variables_at(index)
      ns = namespace_at(index) || ''
      api_map.get_class_variables(ns)
    end

    def get_instance_variables_at(index)
      # @todo There are a lot of other cases that need to be handled here
      node = parent_node_from(index, :def, :defs, :class, :module, :sclass)
      ns = namespace_at(index) || ''
      scope = (node.type == :def ? :instance : :class)
      api_map.get_instance_variables(ns, scope)
    end

    # Get suggestions for code completion at the specified location in the
    # source.
    #
    # @return [Array<Solargraph::Suggestion>] The completion suggestions
    def suggest_at index, filtered: true
      return [] if string_at?(index) or string_at?(index - 1) or comment_at?(index)
      signature = get_signature_at(index)
      unless signature.include?('.')
        if signature.start_with?(':')
          return api_map.get_symbols
        elsif signature.start_with?('@@')
          return get_class_variables_at(index)
        elsif signature.start_with?('@')
          return get_instance_variables_at(index)
        elsif signature.start_with?('$')
          return api_map.get_global_variables
        end
      end
      result = []
      type = nil
      if signature.include?('.')
        type = infer_signature_at(index)
        if type.nil? and signature.include?('.')
          last_period = @code[0..index].rindex('.')
          type = infer_signature_at(last_period)
        end
      end
      if type.nil?
        unless signature.include?('.')
          namespace = namespace_at(index)
          if signature.include?('::')
            parts = signature.split('::', -1)
            ns = parts[0..-2].join('::')
            result = api_map.get_constants(ns, namespace)
          else
            type = infer_literal_node_type(node_at(index - 2))
            return [] if type.nil? and signature.empty? and !@code[0..index].rindex('.').nil? and @code[@code[0..index].rindex('.')..-1].strip == '.'
            if type.nil?
              result.concat get_local_variables_and_methods_at(index)
              result.concat ApiMap.keywords
              result.concat api_map.get_constants('', namespace)
              result.concat api_map.get_constants('')
              result.concat api_map.get_instance_methods('Kernel', namespace)
              result.concat api_map.get_methods('', namespace)
            else
              result.concat api_map.get_instance_methods(type) unless @code[index - 1] != '.'
            end
          end
        end
      else
        result.concat api_map.get_instance_methods(type) unless (type == '' and signature.include?('.'))
      end
      result.keep_if{|s| s.kind != Solargraph::Suggestion::METHOD or s.label.match(/^[a-z0-9_]*(\!|\?|=)?$/i)}
      result = reduce_starting_with(result, word_at(index)) if filtered
      # Use a stable sort to keep the class order (e.g., local methods before superclass methods)
      result.uniq(&:path).sort_by.with_index{ |x, idx| [x.label, idx] }
    end

    def signatures_at index
      sig = signature_index_before(index)
      return [] if sig.nil?
      word = word_at(sig)
      sugg = suggest_at(sig - word.length)
      sugg.select{|s| s.label == word}
    end

    # @return [Array<Solargraph::Suggestion>]
    def define_symbol_at index
      return [] if string_at?(index)
      signature = get_signature_at(index, final: true)
      return [] if signature.to_s.empty?
      node = parent_node_from(index, :class, :module, :def, :defs) || @node
      ns_here = namespace_from(node)
      unless signature.include?('.')
        if local_variable_in_node?(signature, node)
          return get_local_variables_from(node).select{|s| s.label == signature}
        elsif signature.start_with?('@@')
          return api_map.get_class_variables(ns_here).select{|s| s.label == signature}
        elsif signature.start_with?('@')
          return api_map.get_instance_variables(ns_here, (node.type == :def ? :instance : :class)).select{|s| s.label == signature}
        end
      end
      path = infer_path_from_signature_and_node(signature, node)
      ps = []
      ps = api_map.get_path_suggestions(path) unless path.nil?
      return ps unless ps.empty?
      ps = api_map.get_path_suggestions(signature)
      return ps unless ps.empty?
      scope = (node.type == :def ? :instance : :class)
      final = []
      if scope == :instance
        final.concat api_map.get_instance_methods('', namespace_from(node), visibility: [:public, :private, :protected]).select{|s| s.to_s == signature}
      else
        final.concat api_map.get_methods('', namespace_from(node), visibility: [:public, :private, :protected]).select{|s| s.to_s == signature}
      end
      if final.empty? and !signature.include?('.')
        fqns = api_map.find_fully_qualified_namespace(signature, ns_here)
        final.concat api_map.get_path_suggestions(fqns) unless fqns.nil? or fqns.empty?
      end
      final
    end

    def resolve_object_at index
      define_symbol_at index
    end

    # Infer the type of the signature located at the specified index.
    #
    # @example
    #   # Given the following code:
    #   nums = [1, 2, 3]
    #   nums.join
    #   # ...and given an index that points at the end of "nums.join",
    #   # infer_signature_at will identify nums as an Array and the return
    #   # type of Array#join as a String, so the signature's type will be
    #   # String.
    #
    # @return [String]
    def infer_signature_at index
      beg_sig, signature = get_signature_data_at(index)
      # Check for literals first
      return 'Integer' if signature.match(/^[0-9]+?\.?$/)
      literal = nil
      if (signature.empty? and @code[index - 1] == '.') or signature == '[].'
        literal = node_at(index - 2)
      else
        literal = node_at(1 + beg_sig)
      end
      type = infer_literal_node_type(literal)
      if type.nil?
        node = parent_node_from(index, :class, :module, :def, :defs, :block) || @node
        result = infer_signature_from_node signature, node
        if result.nil? or result.empty?
          # The rest of this routine is dedicated to method and block parameters
          arg = nil
          if node.type == :def or node.type == :defs or node.type == :block
            # Check for method arguments
            parts = signature.split('.', 2)
            # @type [Solargraph::Suggestion]
            arg = get_method_arguments_from(node).keep_if{|s| s.to_s == parts[0] }.first
            unless arg.nil?
              if parts[1].nil?
                result = arg.return_type
              else
                result = api_map.infer_signature_type(parts[1], arg.return_type, scope: :instance)
              end
            end
          end
          if arg.nil?
            # Check for yieldparams
            parts = signature.split('.', 2)
            yp = get_yieldparams_at(index).keep_if{|s| s.to_s == parts[0]}.first
            unless yp.nil?
              if parts[1].nil? or parts[1].empty?
                result = yp.return_type
              else
                newsig = parts[1..-1].join('.')
                result = api_map.infer_signature_type(newsig, yp.return_type, scope: :instance)
              end
            end
          end
        #elsif match = result.match(/^\$(\-?[0-9]*)$/)
        #  STDERR.puts "TODO: handle expression variable #{match[1]}"
        end
      else
        if signature.empty? or signature == '[].'
          result = type
        else
          cursed = get_signature_index_at(index)
          if signature.start_with?('[].')
            rest = signature[3..-1]
          else
            if signature.start_with?('.')
              rest = signature[literal.loc.expression.end_pos+(cursed-literal.loc.expression.end_pos)..-1]
            else
              rest = signature
            end
          end
          return type if rest.nil?
          lit_code = @code[literal.loc.expression.begin_pos..literal.loc.expression.end_pos]
          rest = rest[lit_code.length..-1] if rest.start_with?(lit_code)
          rest = rest[1..-1] if rest.start_with?('.')
          rest = rest[0..-2] if rest.end_with?('.')
          if rest.empty?
            result = type
          else
            result = api_map.infer_signature_type(rest, type, scope: :instance)
          end
        end
      end
      result
    end

    def local_variable_in_node?(name, node)
      return true unless find_local_variable_node(name, node).nil?
      if node.type == :def or node.type == :defs
        args = get_method_arguments_from(node).keep_if{|a| a.label == name}
        return true unless args.empty?
      end
      false
    end

    def infer_signature_from_node signature, node, call_node: nil
      inferred = nil
      parts = signature.split('.')
      ns_here = namespace_from(node)
      if parts[0] and parts[0].include?('::')
        sub = get_namespace_or_constant(parts[0], ns_here)
        unless sub.nil?
          return sub if signature.match(/^#{parts[0]}\.$/)
          parts[0] = sub
        end
      end
      unless signature.include?('.')
        fqns = api_map.find_fully_qualified_namespace(signature, ns_here)
        return "Class<#{fqns}>" unless fqns.nil? or fqns.empty?
      end
      start = parts[0]
      return nil if start.nil?
      remainder = parts[1..-1]
      if start.start_with?('@@')
        cv = api_map.get_class_variable_pins(ns_here).select{|s| s.name == start}.first
        unless cv.nil?
          vartype = (cv.return_type || api_map.infer_assignment_node_type(cv.node, cv.namespace))
          return api_map.infer_signature_type(remainder.join('.'), vartype, scope: :instance)
        end
      elsif start.start_with?('@')
        scope = (node.type == :def ? :instance : :class)
        iv = api_map.get_instance_variable_pins(ns_here, scope).select{|s| s.name == start}.first
        unless iv.nil?
          vartype = (iv.return_type || api_map.infer_assignment_node_type(iv.node, iv.namespace))
          return api_map.infer_signature_type(remainder.join('.'), vartype, scope: :instance)
        end
      elsif start.start_with?('$')
        gv = api_map.get_global_variable_pins.select{|s| s.name == start}.first
        unless gv.nil?
          vartype = (gv.return_type || api_map.infer_assignment_node_type(gv.node, gv.namespace))
          return api_map.infer_signature_type(remainder.join('.'), vartype, scope: :instance)
        end
      end
      # @todo There might be some redundancy between find_local_variable_node and call_node
      var = find_local_variable_node(start, node)
      if var.nil?
        arg = get_method_arguments_from(node).select{|s| s.label == start}.first
        if arg.nil?
          scope = (node.type == :def ? :instance : :class)
          type = api_map.infer_signature_type(signature, ns_here, scope: scope, call_node: call_node)
          return type unless type.nil?
        else
          type = arg.return_type
        end
      else
        # Signature starts with a local variable
        type = nil
        lvp = source.local_variable_pins.select{|p| p.name == var.children[0].to_s and p.visible_from?(node) and (!p.nil_assignment? or p.return_type)}.first
        unless lvp.nil?
          type = lvp.return_type
          if type.nil?
            vsig = resolve_node_signature(var.children[1])
            type = infer_signature_from_node vsig, node, call_node: lvp.assignment_node
          end
        end
      end
      unless type.nil?
        if remainder.empty?
          inferred = type
        else
          inferred = api_map.infer_signature_type(remainder.join('.'), type, scope: :instance, call_node: call_node)
        end
      end
      if inferred.nil? and node.respond_to?(:loc)
        index = node.loc.expression.begin_pos
        block_node = parent_node_from(index, :block, :class, :module, :sclass, :def, :defs)
        unless block_node.nil? or block_node.type != :block or block_node.children[0].nil?
          scope_node = parent_node_from(index, :class, :module, :def, :defs) || @node
          meth = get_yielding_method_with_yieldself(block_node, scope_node)
          unless meth.nil?
            match = meth.docstring.all.match(/@yieldself \[([a-z0-9:_]*)/i)
            self_yield = match[1]
            inferred = api_map.infer_signature_type(signature, self_yield, scope: :instance)
          end
        end
      end
      inferred
    end

    # Get the signature at the specified index.
    # A signature is a method call that can start with a constant, method, or
    # variable and does not include any method arguments. Examples:
    #
    # * String.new -> String.new
    # * @x.bar -> @x.bar
    # * y.split(', ').length -> y.split.length
    #
    # @param index [Integer]
    # @return [String]
    def get_signature_at index, final: false
      sig = get_signature_data_at(index)[1]
      if final
        cursor = index
        while @code[cursor] =~ /[a-z0-9_\?]/i
          sig += @code[cursor]
          cursor += 1
          break if cursor >= @code.length
        end
      end
      sig
    end

    def get_signature_index_at index
      get_signature_data_at(index)[0]
    end

    # Get an array of local variables and methods that can be accessed from
    # the specified location in the code.
    #
    # @param index [Integer]
    # @return [Array<Solargraph::Suggestion>]
    def get_local_variables_and_methods_at(index)
      result = []
      local = parent_node_from(index, :class, :module, :def, :defs) || @node
      result += get_local_variables_from(node_at(index))
      scope = namespace_at(index) || @node
      if local.type == :def
        result += api_map.get_instance_methods(scope, visibility: [:public, :private, :protected])
      else
        result += api_map.get_methods(scope, scope, visibility: [:public, :private, :protected])
      end
      if local.type == :def or local.type == :defs
        result += get_method_arguments_from local
      end
      result.concat get_yieldparams_at(index)
      result
    end

    #def get_call_arguments_at index
    #  called = parent_node_from(index, :send)
    #end

    private

    def get_signature_data_at index
      brackets = 0
      squares = 0
      parens = 0
      signature = ''
      index -=1
      in_whitespace = false
      while index >= 0
        break if index > 0 and comment_at?(index - 1)
        unless !in_whitespace and string_at?(index)
          break if brackets > 0 or parens > 0 or squares > 0
          char = @code[index, 1]
          if brackets.zero? and parens.zero? and squares.zero? and [' ', "\n", "\t"].include?(char)
            in_whitespace = true
          else
            if brackets.zero? and parens.zero? and squares.zero? and in_whitespace
              unless char == '.' or @code[index+1..-1].strip.start_with?('.')
                old = @code[index+1..-1]
                nxt = @code[index+1..-1].lstrip
                index += (@code[index+1..-1].length - @code[index+1..-1].lstrip.length)
                break
              end
            end
            if char == ')'
              parens -=1
            elsif char == ']'
              squares -=1
            elsif char == '}'
              brackets -= 1
            elsif char == '('
              parens += 1
            elsif char == '{'
              brackets += 1
            elsif char == '['
              squares += 1
              signature = ".[]#{signature}" if squares == 0 and @code[index-2] != '%'
            end
            if brackets.zero? and parens.zero? and squares.zero?
              break if ['"', "'", ',', ';', '%'].include?(char)
              signature = char + signature if char.match(/[a-z0-9:\._@\$]/i) and @code[index - 1] != '%'
              break if char == '$'
              if char == '@'
                signature = "@#{signature}" if @code[index-1, 1] == '@'
                break
              end
            end
            in_whitespace = false
          end
        end
        index -= 1
      end
      signature = signature[1..-1] if signature.start_with?('.')
      [index + 1, signature]
    end

    # Get a node's arguments as an array of suggestions. The node's type must
    # be a method (:def or :defs).
    #
    # @param node [AST::Node]
    # @return [Array<Suggestion>]
    def get_method_arguments_from node
      return [] unless node.type == :def or node.type == :defs
      param_hash = {}
      cmnt = api_map.get_docstring_for(node)
      unless cmnt.nil?
        tags = cmnt.tags(:param)
        tags.each do |tag|
          param_hash[tag.name] = tag.types[0]
        end
      end
      result = []
      args = node.children[(node.type == :def ? 1 : 2)]
      return result unless args.kind_of?(AST::Node) and args.type == :args
      args.children.each do |arg|
        name = arg.children[0].to_s
        result.push Suggestion.new(name, kind: Suggestion::PROPERTY, insert: name, return_type: param_hash[name])
      end
      result
    end

    def get_yieldparams_at index
      block_node = parent_node_from(index, :block, :class, :module, :def, :defs)
      return [] if block_node.nil? or block_node.type != :block
      scope_node = parent_node_from(index, :class, :module, :def, :defs) || @node
      return [] if block_node.nil?
      get_yieldparams_from block_node, scope_node
    end

    def get_yieldparams_from block_node, scope_node
      return [] unless block_node.kind_of?(AST::Node) and block_node.type == :block
      result = []
      unless block_node.nil? or block_node.children[1].nil?
        ymeth = get_yielding_method(block_node, scope_node)
        yps = []
        unless ymeth.nil? or ymeth.docstring.nil?
          yps = ymeth.docstring.tags(:yieldparam) || []
        end
        self_yield = nil
        meth = get_yielding_method_with_yieldself(block_node, scope_node)
        unless meth.nil?
          match = meth.docstring.all.match(/@yieldself \[([a-z0-9:_]*)/i)
          self_yield = match[1]
          if self_yield == 'self'
            blocksig = resolve_node_signature(block_node.children[0]).split('.')[0..-2].join('.')
            self_yield = infer_signature_from_node(blocksig, scope_node)
          end
        end
        block_node.children[1].children.each_with_index do |a, i|
          rt = nil
          if yps[i].nil? or yps[i].types.nil? or yps[i].types.empty?
            zsig = api_map.resolve_node_signature(block_node.children[0])
            vartype = infer_signature_from_node(zsig.split('.')[0..-2].join('.'), scope_node)
            subtypes = get_subtypes(vartype)
            zpath = infer_path_from_signature_and_node(zsig, scope_node)
            rt = subtypes[i] if METHODS_WITH_YIELDPARAM_SUBTYPES.include?(zpath)
          else
            rt = yps[i].types[0]
          end
          result.push Suggestion.new(a.children[0], kind: Suggestion::PROPERTY, return_type: rt)
        end
        result.concat api_map.get_instance_methods(self_yield, namespace_from(scope_node)) unless self_yield.nil?
      end
      result
    end

    def get_yielding_method block_node, scope_node
      recv = resolve_node_signature(block_node.children[0].children[0])
      fqns = namespace_from(block_node)
      lvarnode = find_local_variable_node(recv, scope_node)
      if lvarnode.nil?
        #sig = api_map.infer_signature_type(recv, fqns)
        sig = infer_signature_from_node(recv, scope_node)
      else
        tmp = resolve_node_signature(lvarnode.children[1])
        sig = infer_signature_from_node tmp, scope_node
      end
      if sig.nil?
        meths = api_map.get_methods(fqns, fqns)
      else
        meths = api_map.get_instance_methods(sig, fqns)
      end
      meths += api_map.get_methods('')
      meth = meths.keep_if{ |s| s.to_s == block_node.children[0].children[1].to_s }.first
      meth
    end

    def get_yielding_method_with_yieldself block_node, scope_node
      meth = get_yielding_method block_node, scope_node
      if meth.nil? or meth.docstring.nil? or !meth.docstring.all.include?('@yieldself')
        meth = nil
        tree = @source.tree_for(block_node)
        unless tree.nil?
          tree.each do |p|
            break if [:def, :defs, :class, :module, :sclass].include?(p.type)
            return get_yielding_method_with_yieldself(p, scope_node) if p.type == :block
          end
        end
      end
      meth
    end

    # @param suggestions [Array<Solargraph::Suggestion>]
    # @param word [String]
    def reduce_starting_with(suggestions, word)
      suggestions.reject { |s|
        !s.label.start_with?(word)
      }
    end

    # Find all the local variables in the node's scope.
    #
    # @return [Array<Solargraph::Suggestion>]
    def get_local_variables_from(node)
      node ||= @node
      namespace = namespace_from(node)
      arr = []
      nil_pins = []
      val_names = []
      @source.local_variable_pins.select{|p| p.visible_from?(node) }.each do |pin|
        if pin.nil_assignment? and pin.return_type.nil?
          nil_pins.push pin
        else
          unless val_names.include?(pin.name)
            arr.push Suggestion.pull(pin)
            val_names.push pin.name
          end
        end
      end
      nil_pins.reject{|p| val_names.include?(p.name)}.each do |pin|
        arr.push Suggestion.pull(pin)
      end
      arr
    end

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

    def find_local_variable_node name, scope
      scope.children.each { |c|
        if c.kind_of?(AST::Node)
          if c.type == :lvasgn and c.children[0].to_s == name
            return c
          else
            unless [:class, :module, :def, :defs].include?(c.type)
              sub = find_local_variable_node(name, c)
              return sub unless sub.nil?
            end
          end
        end
      }
      nil
    end

    def get_namespace_or_constant con, namespace
      parts = con.split('::')
      conc = parts.shift
      result = nil
      is_constant = false
      while parts.length > 0
        result = api_map.find_fully_qualified_namespace("#{conc}::#{parts[0]}", namespace)
        if result.nil? or result.empty?
          pin = api_map.get_constant_pins(conc, namespace).select{|s| s.name == parts[0]}.first
          return nil if pin.nil?
          result = pin.return_type || api_map.infer_assignment_node_type(pin.node, namespace)
          break if result.nil?
          is_constant = true
          conc = result
          parts.shift
        else
          is_constant = false
          conc += "::#{parts.shift}"
        end
      end
      return result if is_constant
    end

    def signature_index_before index
      open_parens = 0
      cursor = index - 1
      while cursor >= 0
        break if cursor < 0
        if @code[cursor] == ')'
          open_parens -= 1
        elsif @code[cursor] == '('
          open_parens += 1
        end
        break if open_parens == 1
        cursor -= 1
      end
      cursor = nil if cursor < 0
      cursor
    end

    def infer_path_from_signature_and_node signature, node
      # @todo Improve this method
      parts = signature.split('.')
      last = parts.pop
      type = infer_signature_from_node(parts.join('.'), node)
      return nil if type.nil?
      "#{type.gsub(/<[a-z0-9:, ]*>/i, '')}##{last}"
    end

    def get_subtypes type
      return nil if type.nil?
      match = type.match(/<([a-z0-9_:, ]*)>/i)
      return [] if match.nil?
      match[1].split(',').map(&:strip)
    end

    # @param template [String]
    def convert_erb template
      result = ''
      i = 0
      in_code = false
      if template.start_with?('<%=')
        i += 3
        result += ';;;'
        in_code = true
      elsif template.start_with? '<%'
        i += 2
        result += ';;'
        in_code = true
      end
      while i < template.length
        if in_code
          if template[i, 2] == '%>'
            i += 2
            result += ';;'
            in_code = false
          else
            result += template[i]
          end
        else
          if template[i, 3] == '<%='
            i += 2
            result += ';;;'
            in_code = true
          elsif template[i, 2] == '<%'
            i += 1
            result += ';;'
            in_code = true
          else
            result += template[i].sub(/[^\s]/, ' ')
          end
        end
        i += 1
      end
      result
    end
  end
end
