require 'parser/current'

module Solargraph
  class CodeMap
    attr_accessor :node
    attr_reader :code
    attr_reader :parsed
    attr_reader :filename
    attr_reader :workspace

    include NodeMethods

    def initialize code: '', filename: nil, workspace: nil, api_map: nil
      @workspace = workspace
      # HACK: Adjust incoming filename's path separator for yardoc file comparisons
      filename = filename.gsub(File::ALT_SEPARATOR, File::SEPARATOR) unless filename.nil? or File::ALT_SEPARATOR.nil?
      @filename = filename
      @api_map = api_map
      @code = code.gsub(/\r/, '')
      tries = 0
      tmp = @code
      begin
        # HACK: The current file is parsed with a trailing underscore to fix
        # incomplete trees resulting from short scripts (e.g., a lone variable
        # assignment).
        node, @comments = Parser::CurrentRuby.parse_with_comments(tmp + "\n_")
        @node = self.api_map.append_node(node, @comments, filename)
        @parsed = tmp
        @code.freeze
        @parsed.freeze
      rescue Parser::SyntaxError => e
        if tries < 10
          tries += 1
          if tries == 10 and e.message.include?('token $end')
            tmp += "\nend"
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
            tmp = tmp[0..spot] + repl + tmp[spot+repl.length+1..-1].to_s
          end
          retry
        end
        raise e
      end
    end

    # @return [Solargraph::ApiMap]
    def api_map
      @api_map ||= ApiMap.new(workspace)
    end

    # Get the offset of the specified line and column.
    # The offset (also called the "index") is typically used to identify the
    # cursor's location in the code when generating suggestions.
    # The line and column numbers should start at zero.
    #
    # @return [Integer]
    def get_offset line, col
      offset = 0
      if line > 0
        @code.lines[0..line - 1].each { |l|
          offset += l.length
        }
      end
      offset + col
    end

    def tree_at(index)
      arr = []
      arr.push @node
      inner_node_at(index, @node, arr)
      arr
    end

    def node_at(index)
      tree_at(index).first
    end

    # Determine if the specified index is inside a string.
    #
    # @return [Boolean]
    def string_at?(index)
      n = node_at(index)
      n.kind_of?(AST::Node) and n.type == :str
    end

    # Determine if the specified index is inside a comment.
    #
    # @return [Boolean]
    def comment_at?(index)
      @comments.each do |c|
        return true if index > c.location.expression.begin_pos and index <= c.location.expression.end_pos
      end
      false
    end

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

    def phrase_at index
      word = ''
      cursor = index - 1
      while cursor > -1
        char = @code[cursor, 1]
        break if char.nil? or char == ''
        break unless char.match(/[\s;=\(\)\[\]\{\}]/).nil?
        word = char + word
        cursor -= 1
      end
      word
    end

    def word_at index
      word = ''
      cursor = index - 1
      while cursor > -1
        char = @code[cursor, 1]
        break if char.nil? or char == ''
        break unless char.match(/[a-z0-9_]/i)
        word = char + word
        cursor -= 1
      end
      word
    end

    def get_class_variables_at(index)
      ns = namespace_at(index) || ''
      api_map.get_class_variables(ns)
    end

    def get_instance_variables_at(index)
      node = parent_node_from(index, :def, :defs, :class, :module)
      ns = namespace_at(index) || ''
      api_map.get_instance_variables(ns, (node.type == :def ? :instance : :class))
    end

    # Get suggestions for code completion at the specified location in the
    # source.
    #
    # @return [Array<Suggestions>] The completion suggestions
    def suggest_at index, filtered: false, with_snippets: false
      return [] if string_at?(index) or string_at?(index - 1) or comment_at?(index)
      result = []
      phrase = phrase_at(index)
      signature = get_signature_at(index)
      namespace = namespace_at(index)
      if signature.include?('.')
        # Check for literals first
        type = infer_literal_node_type(node_at(index - 2))
        if type.nil?
          nearest = @code[0, index].rindex('.')
          revised = signature[0..nearest-index-1]
          type = infer_signature_at(nearest) unless revised.empty?
          if !type.nil?
            result.concat api_map.get_instance_methods(type) unless type.nil?
          elsif !revised.include?('.')
            fqns = api_map.find_fully_qualified_namespace(revised, namespace)
            result.concat api_map.get_methods(fqns) unless fqns.nil?
          end
        else
          result.concat api_map.get_instance_methods(type)
        end
      elsif signature.start_with?('@@')
        result.concat get_class_variables_at(index)
      elsif signature.start_with?('@')
        result.concat get_instance_variables_at(index)
      elsif phrase.start_with?('$')
        result.concat api_map.get_global_variables
      elsif phrase.include?('::')
        parts = phrase.split('::', -1)
        ns = parts[0..-2].join('::')
        if parts.last.include?('.')
          ns = parts[0..-2].join('::') + '::' + parts.last[0..parts.last.index('.')-1]
          result = api_map.get_methods(ns)
        else
          result = api_map.namespaces_in(ns, namespace)
        end
      else
        current_namespace = namespace_at(index)
        parts = current_namespace.to_s.split('::')
        result += get_snippets_at(index) if with_snippets
        result += get_local_variables_and_methods_at(index)
        result += ApiMap.get_keywords
        while parts.length > 0
          ns = parts.join('::')
          result += api_map.namespaces_in(ns, namespace)
          parts.pop
        end
        result += api_map.namespaces_in('')
        result += api_map.get_instance_methods('Kernel')
      end
      result = reduce_starting_with(result, word_at(index)) if filtered
      result.uniq{|s| s.path}.sort{|a,b| a.label <=> b.label}
    end

    def signatures_at index
      sig = signature_index_before(index)
      return [] if sig.nil?
      word = word_at(sig)
      suggest_at(sig).reject{|s| s.label != word}
    end

    def resolve_object_at index
      return [] if string_at?(index)
      signature = get_signature_at(index)
      cursor = index
      while @code[cursor] =~ /[a-z0-9_\?]/i
        signature += @code[cursor]
        cursor += 1
        break if cursor >= @code.length
      end
      return [] if signature.to_s == ''
      path = nil
      ns_here = namespace_at(index)
      node = parent_node_from(index, :class, :module, :def, :defs) || @node
      parts = signature.split('.')
      if parts.length > 1
        beginner = parts[0..-2].join('.')
        type = infer_signature_from_node(beginner, node)
        ender = parts.last
        path = "#{type}##{ender}"
      else
        if local_variable_in_node?(signature, node)
          path = infer_signature_from_node(signature, node)
        elsif signature.start_with?('@')
          path = api_map.infer_instance_variable(signature, ns_here, (node.type == :def ? :instance : :class))
        else
          path = signature
        end
        if path.nil?
          path = api_map.find_fully_qualified_namespace(signature, ns_here)
        end
      end
      return [] if path.nil?
      return api_map.yard_map.objects(path, ns_here)
    end

    def infer_signature_at index
      signature = get_signature_at(index)
      node = parent_node_from(index, :class, :module, :def, :defs) || @node
      infer_signature_from_node signature, node
    end

    def local_variable_in_node?(name, node)
      return true unless find_local_variable_node(name, node).nil?
      if node.type == :def or node.type == :defs
        args = get_method_arguments_from(node).keep_if{|a| a.label == name}
        return true unless args.empty?
      end
      false
    end

    def infer_signature_from_node signature, node
      inferred = nil
      parts = signature.split('.')
      ns_here = namespace_from(node)
      start = parts[0]
      return nil if start.nil?
      remainder = parts[1..-1]
      scope = :instance
      var = find_local_variable_node(start, node)
      if var.nil?
        return api_map.infer_signature_type(signature, ns_here)
      else
        # Signature starts with a local variable
        type = get_type_comment(var)
        type = infer_literal_node_type(var.children[1]) if type.nil?
        if type.nil?
          vsig = resolve_node_signature(var.children[1])
          type = infer_signature_from_node vsig, node
        end
      end
      unless type.nil?
        if remainder.empty?
          inferred = type
        else
          inferred = api_map.infer_signature_type(remainder.join('.'), type, scope: scope)
        end
      end
      inferred
    end

    def suggest_for_signature_at index
      result = []
      type = infer_signature_at(index)
      result.concat api_map.get_instance_methods(type) unless type.nil?
      result
    end

    def get_type_comment node
      obj = nil
      cmnt = api_map.get_comment_for(node)
      unless cmnt.nil?
        tag = cmnt.tag(:type)
        obj = tag.types[0] unless tag.nil? or tag.types.empty?
      end
      obj
    end

    # Get the signature at the specified index.
    # A signature is a method call that can start with a constant, method, or
    # variable and does not include any method arguments. Examples:
    #
    # Code                  Signature
    # -----------------------------------------
    # String.new            String.new
    # @x.bar                @x.bar
    # y.split(', ').length  y.split.length
    #
    # @param index [Integer]
    # @return [String]
    def get_signature_at index
      brackets = 0
      squares = 0
      parens = 0
      signature = ''
      index -=1
      while index >= 0
        break if brackets > 0 or parens > 0 or squares > 0
        char = @code[index, 1]
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
        end
        if brackets == 0 and parens == 0 and squares == 0
          break if ['"', "'", ',', ' ', "\t", "\n"].include?(char)
          signature = char + signature if char.match(/[a-z0-9:\._@]/i)
          if char == '@'
            signature = "@#{signature}" if @code[index-1, 1] == '@'
            break
          end
        end
        index -= 1
      end
      signature
    end

    # Build a signature from the specified node. This method returns the node
    # as an array of strings.
    #
    # @return [Array<String>]
    def build_signature(node, parts)
      if node.kind_of?(AST::Node)
        if node.type == :send
          parts.unshift node.children[1].to_s
        elsif node.type == :const
          parts.unshift unpack_name(node)
        end
        build_signature(node.children[0], parts)
      end
    end

    def get_snippets_at(index)
      result = []
      Snippets.definitions.each_pair { |name, detail|
        matched = false
        prefix = detail['prefix']
        while prefix.length > 0
          if @code[index-prefix.length, prefix.length] == prefix
            matched = true
            break
          end
          prefix = prefix[0..-2]
        end
        if matched
          result.push Suggestion.new(detail['prefix'], kind: Suggestion::SNIPPET, detail: name, insert: detail['body'].join("\r\n"))
        end
      }
      result
    end

    # Get an array of local variables and methods that can be accessed from
    # the specified location in the code.
    #
    # @return [Array<Solargraph::Suggestion>]
    def get_local_variables_and_methods_at(index)
      result = []
      local = parent_node_from(index, :class, :module, :def, :defs) || @node
      result += get_local_variables_from(local)
      scope = namespace_at(index) || @node
      if local.type == :def
        result += api_map.get_instance_methods(scope, visibility: [:public, :private, :protected])
      else
        result += api_map.get_methods(scope, visibility: [:public, :private, :protected])
      end
      if local.type == :def or local.type == :defs
        result += get_method_arguments_from local
      end
      # Get block parameter variables
      block_node = parent_node_from(index, :block)
      unless block_node.nil? or block_node.children[1].nil?
        block_node.children[1].children.each do |a|
          result.push Suggestion.new(a.children[0], kind: Suggestion::PROPERTY)
        end
      end
      result += api_map.get_methods('Kernel')
      result
    end

    private

    def get_method_arguments_from node
      param_hash = {}
      cmnt = api_map.get_comment_for(node)
      unless cmnt.nil?
        tags = cmnt.tags(:param)
        tags.each do |tag|
          param_hash[tag.name] = tag.types[0]
        end
      end
      result = []
      args = node.children[1]
      return result unless args.kind_of?(AST::Node) and args.type == :args
      args.children.each do |arg|
        name = arg.children[0].to_s
        result.push Suggestion.new(name, kind: Suggestion::PROPERTY, insert: name, return_type: param_hash[name])
      end
      result
    end

    # @param suggestions [Array<Solargraph::Suggestion>]
    # @param word [String]
    def reduce_starting_with(suggestions, word)
      suggestions.reject { |s|
        !s.label.start_with?(word)
      }
    end

    def get_local_variables_from(node)
      node ||= @node
      arr = []
      node.children.each { |c|
        if c.kind_of?(AST::Node)
          if c.type == :lvasgn
            arr.push Suggestion.new(c.children[0], kind: Suggestion::VARIABLE, documentation: api_map.get_comment_for(c))
          else
            arr += get_local_variables_from(c) unless [:class, :module, :def, :defs].include?(c.type)
          end
        end
      }
      arr
    end

    def inner_node_at(index, node, arr)
      node.children.each { |c|
        if c.kind_of?(AST::Node)
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
      }
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

    def beginning_of_line_from str, i
      while i > 0 and str[i] != "\n"
        i -= 1
      end
      if i > 0 and str[i..-1].strip == ''
        i = beginning_of_line_from str, i -1
      end
      i
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
  end
end
