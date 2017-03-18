require 'parser/current'

module Solargraph
  class CodeMap
    attr_accessor :node
    attr_accessor :api_map
    
    include NodeMethods
    
    def initialize code: '', filename: nil, workspace: nil
      workspace = nil
      unless filename.nil?
        filename = filename.gsub(File::ALT_SEPARATOR, File::SEPARATOR) unless File::ALT_SEPARATOR.nil?
        workspace = CodeMap.find_workspace(filename)
      end
      @api_map = ApiMap.new(workspace)
      #unless workspace.nil?
      #  files = Dir[File.join workspace, 'lib', '**', '*.rb'] + Dir[File.join workspace, 'app', '**', '*.rb']
      #  files.each { |f|
      #    unless filename == f
      #      @api_map.append_file f
      #    end
      #  }
      #end

      @code = code.gsub(/\r/, '')
      tries = 0
      # Hide incomplete code to avoid syntax errors
      tmp = "#{@code}\nX".gsub(/[\.@]([\s])/, '#\1').gsub(/([\A\s]?)def([\s]*?[\n\Z])/, '\1#ef\2')
      #tmp = code
      begin
        @node, comments = Parser::CurrentRuby.parse_with_comments(tmp)
        @api_map.append_node(@node, comments, filename)
      rescue Parser::SyntaxError => e
        if tries < 10
          tries += 1
          spot = e.diagnostic.location.begin_pos
          if spot == tmp.length
            tmp = tmp[0..-2] + '#'
          else
            tmp = tmp[0..spot] + '#' + tmp[spot+2..-1].to_s
          end
          retry
        end
        raise e
      end
    end

    def self.find_workspace filename
      return nil if filename.nil?
      dirname = filename
      lastname = nil
      result = nil
      until dirname == lastname
        if File.file?("#{dirname}/Gemfile")
          result = dirname
          break
        end
        lastname = dirname
        dirname = File.dirname(dirname)
      end
      result ||= File.dirname(filename)
      result.gsub!(File::ALT_SEPARATOR, File::SEPARATOR) unless File::ALT_SEPARATOR.nil?
      result
    end

    def get_offset line, col
      offset = 0
      if line > 0
        @code.lines[0..line - 1].each { |l|
          offset += l.length
        }
      end
      offset + col
    end

    def merge node
      api_map.merge node
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

    def string_at?(index)
      n = node_at(index)
      n.kind_of?(AST::Node) and n.type == :str
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

    def namespace_at(index)
      tree = tree_at(index)
      return nil if tree.length == 0
      node = parent_node_from(index, :module, :class)
      slice = tree[(tree.index(node) || 0)..-1]
      parts = []
      slice.reverse.each { |n|
        if n.type == :class or n.type == :module
          parts.push unpack_name(n.children[0])
        end
      }
      parts.join("::")
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

    def get_instance_variables_at(index)
      node = parent_node_from(index, :def, :defs, :class, :module)
      ns = namespace_at(index) || ''
      @api_map.get_instance_variables(ns, (node.type == :def ? :instance : :class))
    end

    def suggest_at index, filtered: true, with_snippets: false
      return [] if string_at?(index)
      result = []
      phrase = phrase_at(index)
      if phrase.start_with?('@')
        if phrase.include?('.')
          result = []
          # TODO: Temporarily assuming one period
          var = phrase[0..phrase.index('.')-1]
          ns = namespace_at(index)
          obj = @api_map.infer_instance_variable(var, ns)
          result = @api_map.get_instance_methods(obj) unless obj.nil?
        else
          result = get_instance_variables_at(index)
        end
      elsif phrase.start_with?('$')
        result += @api_map.get_global_variables
      elsif phrase.start_with?(':') and !phrase.start_with?('::')
        # TODO: It's a symbol. Nothing to do for now.
        return []
      elsif phrase.include?('::')
        parts = phrase.split('::', -1)
        ns = parts[0..-2].join('::')
        if parts.last.include?('.')
          ns = parts[0..-2].join('::') + '::' + parts.last[0..parts.last.index('.')-1]
          result = @api_map.get_methods(ns)
        else
          result = @api_map.namespaces_in(ns)
        end
      elsif phrase.include?('.')
        # It's a method call
        # TODO: For now we're assuming only one period. That's obviously a bad assumption.
        #base = phrase[0..phrase.index('.')-1]
        #ns_here = namespace_at(index)
        #result = @api_map.get_methods(base, ns_here)
        #scope = parent_node_from(index, :class, :module, :def, :defs) || @node
        #var = find_local_variable_node(base, scope)
        #unless var.nil?
        #  obj = infer(var.children[1])
        #  result = @api_map.get_instance_methods(obj) unless obj.nil?
        #end
        
        # TODO: Alternate version that resolves signature
        result = resolve_signature_at index
      else
        current_namespace = namespace_at(index)
        parts = current_namespace.to_s.split('::')
        result += get_snippets_at(index) if with_snippets
        result += get_local_variables_and_methods_at(index)
        result += ApiMap.get_keywords(without_snippets: with_snippets)
        while parts.length > 0
          ns = parts.join('::')
          result += @api_map.namespaces_in(ns)
          parts.pop
        end
        result += @api_map.namespaces_in('')
      end
      result = reduce_starting_with(result, word_at(index)) if filtered
      result
    end
    
    def resolve_signature_at index
      signature = get_signature_at(index)
      ns_here = namespace_at(index)
      parts = signature.split('.')
      first = parts.shift
      scope = parent_node_from(index, :class, :module, :def, :defs) || @node
      var = find_local_variable_node(first, scope)
      if var.nil?
        if parts.length == 0
          return @api_map.get_methods(first, ns_here)
        end
        obj = get_method_return_value first, ns_here, parts.shift
        while parts.length > 0
          obj = get_instance_method_return_value obj, ns_here, parts.shift
        end
        return @api_map.get_instance_methods(obj) unless obj.nil?
      else
        obj = infer(var.children[1])
        while parts.length > 0
          obj = get_instance_method_return_value obj, ns_here, parts.shift
        end
        return @api_map.get_instance_methods(obj) unless obj.nil?
      end
    end

    def get_method_return_value namespace, root, method
      meths = @api_map.get_methods(namespace, root).delete_if{ |m| m.label != method }
      meths.each { |m|
        unless m.documentation.nil?
          match = m.documentation.all.match(/@return \[([a-z0-9:_]*)/i)
          klass = match[1]
          return klass unless klass.nil?
        end
      }
      'Object'
    end

    def get_instance_method_return_value namespace, root, method
      meths = @api_map.get_instance_methods(namespace, root).delete_if{ |m| m.label != method }
      meths.each { |m|
        unless m.documentation.nil?
          match = m.documentation.all.match(/@return \[([a-z0-9:_]*)/i)
          return match[1] unless match.nil?
        end
      }
      'Object'
    end

    def get_signature_at index
      #node = node_at(index - 1)
      #return '' unless node.type == :send
      #parts = []
      #build_signature(node, parts)
      #return parts.join('.')

      # TODO: Alternate rough version
      brackets = 0
      squares = 0
      parens = 0
      signature = ''
      index -=1
      while index > 0
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
          signature = char + signature if char.match(/[a-z0-9:\._]/i)
        end
        index -= 1
      end
      signature
    end

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
          result.push Suggestion.new(detail['prefix'], kind: Suggestion::KEYWORD, detail: name, insert: detail['body'].join("\r\n"))
        end
      }
      result
    end

    def get_local_variables_and_methods_at(index)
      result = []
      local = parent_node_from(index, :class, :module, :def, :defs) || @node
      result += get_local_variables_from(local)
      scope = namespace_at(index) || @node
      if local.type == :def
        result += @api_map.get_instance_methods(scope)
      else
        result += @api_map.get_methods(scope)
      end
      result += @api_map.get_methods('Kernel')
      result    
    end
    
    private

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
            arr.push Suggestion.new(c.children[0], kind: Suggestion::VARIABLE)
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
    
  end
end
