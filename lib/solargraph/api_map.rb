require 'rubygems'
require 'parser/current'
require 'thread'

module Solargraph
  class ApiMap
    autoload :Config,    'solargraph/api_map/config'
    autoload :Cache,     'solargraph/api_map/cache'
    autoload :MethodPin, 'solargraph/api_map/method_pin'
    autoload :AttrPin,   'solargraph/api_map/attr_pin'
    autoload :IvarPin,   'solargraph/api_map/ivar_pin'
    autoload :CvarPin,   'solargraph/api_map/cvar_pin'
    autoload :SymbolPin, 'solargraph/api_map/symbol_pin'

    @@yard_map_cache = {}
    @@semaphore = Mutex.new

    KEYWORDS = [
      '__ENCODING__', '__LINE__', '__FILE__', 'BEGIN', 'END', 'alias', 'and',
      'begin', 'break', 'case', 'class', 'def', 'defined?', 'do', 'else',
      'elsif', 'end', 'ensure', 'false', 'for', 'if', 'in', 'module', 'next',
      'nil', 'not', 'or', 'redo', 'rescue', 'retry', 'return', 'self', 'super',
      'then', 'true', 'undef', 'unless', 'until', 'when', 'while', 'yield'
    ].freeze

    MAPPABLE_NODES = [
      :array, :hash, :str, :dstr, :int, :float, :sym, :block, :class, :sclass,
      :module, :def, :defs, :ivasgn, :gvasgn, :lvasgn, :cvasgn, :casgn,
      :or_asgn, :const, :lvar, :args, :kwargs
    ].freeze

    MAPPABLE_METHODS = [
      :include, :extend, :require, :autoload, :attr_reader, :attr_writer,
      :attr_accessor, :private, :public, :protected
    ].freeze

    METHODS_RETURNING_SELF = [
      'clone', 'dup', 'freeze', 'taint', 'untaint'
    ].freeze

    include NodeMethods
    include YardMethods

    # The root directory of the project. The ApiMap will search here for
    # additional files to parse and analyze.
    #
    # @return [String]
    attr_reader :workspace

    # @return [Array<String>]
    attr_reader :required

    # @param workspace [String]
    def initialize workspace = nil
      @workspace = workspace.gsub(/\\/, '/') unless workspace.nil?
      clear
      unless @workspace.nil?
        config = ApiMap::Config.new(@workspace)
        config.included.each { |f|
          unless config.excluded.include?(f)
            append_file f
          end
        }
      end
    end

    # @return [Solargraph::YardMap]
    def yard_map
      @@semaphore.synchronize {
        @yard_map ||= @@yard_map_cache[[required, workspace]] || Solargraph::YardMap.new(required: required, workspace: workspace)
        @@yard_map_cache[[required, workspace]] ||= @yard_map
      }
    end

    # Add a file to the map.
    #
    # @param filename [String]
    # @return [AST::Node]
    def append_file filename
      append_source File.read(filename), filename
    end

    # Add a string of source code to the map.
    #
    # @param text [String]
    # @param filename [String]
    # @return [AST::Node]
    def append_source text, filename = nil
      @file_source[filename] = text
      begin
        node, comments = Parser::CurrentRuby.parse_with_comments(text)
        append_node(node, comments, filename)
      rescue Parser::SyntaxError => e
        STDERR.puts "Error parsing '#{filename}': #{e.message}"
        nil
      end
    end

    # Add an AST node to the map.
    #
    # @return [AST::Node]
    def append_node node, comments, filename = nil
      @stale = true
      @file_comments[filename] = associate_comments(node, comments)
      mapified = reduce(node, @file_comments[filename])
      root = AST::Node.new(:begin, [filename])
      root = root.append mapified
      @file_nodes[filename] = root
      @required.uniq!
      #process_maps
      root
    end

    def refresh force = false
      process_maps if @stale or force
    end

    # Get the docstring associated with a node.
    #
    # @param node [AST::Node]
    # @return [YARD::Docstring]
    def get_comment_for node
      filename = get_filename_for(node)
      return nil if @file_comments[filename].nil?
      @file_comments[filename][node.loc]
    end

    # @return [Array<Solargraph::Suggestion>]
    def self.get_keywords
      @keyword_suggestions ||= (KEYWORDS + MAPPABLE_METHODS).map{ |s|
        Suggestion.new(s.to_s, kind: Suggestion::KEYWORD, detail: 'Keyword')
      }.freeze
    end

    def namespaces
      refresh
      @namespace_map.keys
    end

    def namespace_exists? name, root = ''
      !find_fully_qualified_namespace(name, root).nil?
    end

    def namespaces_in name, root = ''
      refresh
      result = []
      result += inner_namespaces_in(name, root, [])
      result += yard_map.get_constants name, root
      fqns = find_fully_qualified_namespace(name, root)
      unless fqns.nil?
        nodes = get_namespace_nodes(fqns)
        get_include_strings_from(*nodes).each { |i|
          result += yard_map.get_constants(i, root)
        }
      end
      result
    end

    def find_fully_qualified_namespace name, root = '', skip = []
      refresh
      return nil if skip.include?(root)
      skip.push root
      if name == ''
        if root == ''
          return ''
        else
          return find_fully_qualified_namespace(root, '', skip)
        end
      else
        if (root == '')
          return name unless @namespace_map[name].nil?
          get_include_strings_from(*@file_nodes.values).each { |i|
            reroot = "#{root == '' ? '' : root + '::'}#{i}"
            recname = find_fully_qualified_namespace name.to_s, reroot, skip
            return recname unless recname.nil?
          }
        else
          roots = root.to_s.split('::')
          while roots.length > 0
            fqns = roots.join('::') + '::' + name
            return fqns unless @namespace_map[fqns].nil?
            roots.pop
          end
          return name unless @namespace_map[name].nil?
          get_include_strings_from(*@file_nodes.values).each { |i|
            recname = find_fully_qualified_namespace name, i, skip
            return recname unless recname.nil?
          }
        end
      end
      yard_map.find_fully_qualified_namespace(name, root)
    end

    def get_namespace_nodes(fqns)
      return @file_nodes.values if fqns == '' or fqns.nil?
      refresh
      @namespace_map[fqns] || []
    end

    def get_instance_variables(namespace, scope = :instance)
      refresh
      result = []
      ip = @ivar_pins[namespace]
      unless ip.nil?
        ip.select{ |pin| pin.scope == scope }.each do |pin|
          result.push pin.suggestion
        end
      end
      result
    end

    def get_class_variables(namespace)
      refresh
      result = []
      ip = @cvar_pins[namespace]
      unless ip.nil?
        ip.each do |pin|
          result.push pin.suggestion
        end
      end
      result
    end

    def get_symbols
      result = []
      @symbol_pins.each do |pin|
        result.push pin.suggestion
      end
      result
    end

    def find_parent(node, *types)
      parents = @parent_stack[node]
      parents.each { |p|
        return p if types.include?(p.type)
      }
      nil
    end

    def get_root_for(node)
      s = @parent_stack[node]
      return nil if s.nil?
      return node if s.empty?
      s.last
    end

    def get_filename_for(node)
      root = get_root_for(node)
      root.nil? ? nil : root.children[0]
    end

    def yardoc_has_file?(file)
      return false if workspace.nil?
      if @yardoc_files.nil?
        @yardoc_files = []
        yard_options[:include].each { |glob|
          Dir[File.join workspace, glob].each { |f|
            @yardoc_files.push File.absolute_path(f)
          }
        }
      end
      @yardoc_files.include?(file)
    end

    def infer_instance_variable(var, namespace, scope)
      result = nil
      vn = nil
      fqns = find_fully_qualified_namespace(namespace)
      unless fqns.nil?
        get_namespace_nodes(fqns).each { |node|
          vn = find_instance_variable_assignment(var, node, scope)
          break unless vn.nil?
        }
      end
      result = infer_assignment_node_type(vn, namespace) unless vn.nil?
      result
    end

    def infer_class_variable(var, namespace)
      result = nil
      vn = nil
      fqns = find_fully_qualified_namespace(namespace)
      unless fqns.nil?
        get_namespace_nodes(fqns).each { |node|
          vn = find_class_variable_assignment(var, node)
          break unless vn.nil?
        }
      end
      unless vn.nil?
        cmnt = get_comment_for(vn)
        unless cmnt.nil?
          tag = cmnt.tag(:type)
          result = tag.types[0] unless tag.nil? or tag.types.empty?
        end
        result = infer_literal_node_type(vn.children[1]) if result.nil?
        if result.nil?
          signature = resolve_node_signature(vn.children[1])
          result = infer_signature_type(signature, namespace)
        end
      end
      result
    end

    def find_instance_variable_assignment(var, node, scope)
      node.children.each { |c|
        if c.kind_of?(AST::Node)
          is_inst = !find_parent(c, :def).nil?
          if c.type == :ivasgn and ( (scope == :instance and is_inst) or (scope != :instance and !is_inst) )
            if c.children[0].to_s == var
              return c
            end
          else
            inner = find_instance_variable_assignment(var, c, scope)
            return inner unless inner.nil?
          end
        end
      }
      nil
    end

    def find_class_variable_assignment(var, node)
      node.children.each { |c|
        next unless c.kind_of?(AST::Node)
        if c.type == :cvasgn
          if c.children[0].to_s == var
            return c
          end
        else
          inner = find_class_variable_assignment(var, c)
          return inner unless inner.nil?
        end
      }
      nil
    end

    def get_global_variables
      # TODO: Get them
      []
    end

    def infer_assignment_node_type node, namespace
      type = cache.get_assignment_node_type(node, namespace)
      if type.nil?
        cmnt = get_comment_for(node)
        if cmnt.nil?
          name_i = (node.type == :casgn ? 1 : 0) 
          sig_i = (node.type == :casgn ? 2 : 1)
          type = infer_literal_node_type(node.children[sig_i])
          if type.nil?
            sig = resolve_node_signature(node.children[sig_i])
            # Avoid infinite loops from variable assignments that reference themselves
            return nil if node.children[name_i].to_s == sig.split('.').first
            type = infer_signature_type(sig, namespace)
          end
        else
          t = cmnt.tag(:type)
          if t.nil?
            sig = resolve_node_signature(node.children[1])
            type = infer_signature_type(sig, namespace)
          else
            type = t.types[0]
          end
        end
        cache.set_assignment_node_type(node, namespace, type)
      end
      type
    end

    def infer_signature_type signature, namespace, scope: :class
      cached = cache.get_signature_type(signature, namespace, scope)
      return cached unless cached.nil?
      return nil if signature.nil? or signature.empty?
      result = nil
      if namespace.end_with?('#class')
        result = infer_signature_type signature, namespace[0..-7], scope: (scope == :class ? :instance : :class)
      else
        parts = signature.split('.', 2)
        if parts[0].start_with?('@@')
          type = infer_class_variable(parts[0], namespace)
          if type.nil? or parts.empty?
            result = inner_infer_signature_type(parts[1], type, scope: :instance)
          else
            result = type
          end
        elsif parts[0].start_with?('@')
          type = infer_instance_variable(parts[0], namespace, scope)
          if type.nil? or parts.empty?
            result = inner_infer_signature_type(parts[1], type, scope: :instance)
          else
            result = type
          end
        else
          type = find_fully_qualified_namespace(parts[0], namespace)
          if type.nil?
            # It's a method call
            type = inner_infer_signature_type(parts[0], namespace, scope: scope)
            if parts[1].nil?
              result = type
            else
              result = inner_infer_signature_type(parts[1], type, scope: :instance)
            end
          else
            result = inner_infer_signature_type(parts[1], type, scope: :class)
          end
        end
      end
      cache.set_signature_type signature, namespace, scope, result
      result
    end

    def get_namespace_type namespace, root = ''
      type = nil
      fqns = find_fully_qualified_namespace(namespace, root)
      nodes = get_namespace_nodes(fqns)
      unless nodes.nil? or nodes.empty? or !nodes[0].kind_of?(AST::Node)
        type = nodes[0].type if [:class, :module].include?(nodes[0].type)
      end
      type
    end

    # Get an array of singleton methods that are available in the specified
    # namespace.
    #
    # @return [Array<Solargraph::Suggestion>]
    def get_methods(namespace, root = '', visibility: [:public])
      refresh
      namespace = clean_namespace_string(namespace)
      meths = []
      meths += inner_get_methods(namespace, root, []) #unless has_yardoc?
      yard_meths = yard_map.get_methods(namespace, root, visibility: visibility)
      if yard_meths.any?
        meths.concat yard_meths
      else
        type = get_namespace_type(namespace, root)
        if type == :class
          meths += yard_map.get_instance_methods('Class')
        elsif type == :module
          meths += yard_map.get_methods('Module')
        end
        meths
      end
    end

    # Get an array of instance methods that are available in the specified
    # namespace.
    #
    # @return [Array<Solargraph::Suggestion>]
    def get_instance_methods(namespace, root = '', visibility: [:public])
      refresh
      namespace = clean_namespace_string(namespace)
      if namespace.end_with?('#class')
        return get_methods(namespace.split('#').first, root, visibility: visibility)
      end
      meths = []
      meths += inner_get_instance_methods(namespace, root, [], visibility) #unless has_yardoc?
      fqns = find_fully_qualified_namespace(namespace, root)
      yard_meths = yard_map.get_instance_methods(fqns, '', visibility: visibility)
      if yard_meths.any?
        meths.concat yard_meths
      else
        type = get_namespace_type(namespace, root)
        if type == :class
          meths += yard_map.get_instance_methods('Object')
        elsif type == :module
          meths += yard_map.get_instance_methods('Module')
        end
      end
      meths
    end

    def get_superclass(namespace, root = '')
      fqns = find_fully_qualified_namespace(namespace, root)
      nodes = get_namespace_nodes(fqns)
      nodes.each { |n|
        if n.kind_of?(AST::Node)
          if n.type == :class and !n.children[1].nil?
            return unpack_name(n.children[1])
          end
        end
      }
      return nil
    end

    def self.current
      if @current.nil?
        @current = ApiMap.new
        @current.merge(Parser::CurrentRuby.parse(File.read("#{Solargraph::STUB_PATH}/ruby/2.3.0/core.rb")))
      end
      @current
    end

    def get_include_strings_from *nodes
      arr = []
      nodes.each { |node|
        next unless node.kind_of?(AST::Node)
        arr.push unpack_name(node.children[2]) if (node.type == :send and node.children[1] == :include)
        node.children.each { |n|
          arr += get_include_strings_from(n) if n.kind_of?(AST::Node) and n.type != :class and n.type != :module
        }
      }
      arr
    end

    def code_for node
      src = @file_source[get_filename_for(node)]
      return nil if src.nil?
      b = node.location.expression.begin.begin_pos
      e = node.location.expression.end.end_pos
      src[b..e].strip.gsub(/,$/, '')
    end  

    # Update the YARD documentation for the current workspace.
    #
    def update_yardoc
      if workspace.nil?
        STDERR.puts "No workspace specified for yardoc update."
      else
        Dir.chdir(workspace) do
          STDERR.puts "Updating the yardoc for #{workspace}..."
          cmd = "yardoc -e #{Solargraph::YARD_EXTENSION_FILE}"
          STDERR.puts "Update yardoc with #{cmd}"
          STDERR.puts `#{cmd}`
          unless $?.success?
            STDERR.puts "There was an error processing the workspace yardoc."
          end
        end
        @@semaphore.synchronize {
          @@yard_map_cache.clear
        }
        end
    end

    private

    def clear
      @stale = false
      @file_source = {}
      @file_nodes = {}
      @file_comments = {}
      @parent_stack = {}
      @namespace_map = {}
      @namespace_tree = {}
      @required = []
    end

    def process_maps
      cache.clear
      @ivar_pins = {}
      @cvar_pins = {}
      @method_pins = {}
      @symbol_pins = []
      @attr_nodes = {}
      @namespace_includes = {}
      @superclasses = {}
      @parent_stack = {}
      @namespace_map = {}
      @namespace_tree = {}
      @file_nodes.values.each { |f|
        map_parents f
        map_namespaces f
      }
      @stale = false
    end

    # @return [Solargraph::ApiMap::Cache]
    def cache
      @cache ||= Cache.new
    end

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

    def inner_get_methods(namespace, root = '', skip = [])
      meths = []
      return meths if skip.include?(namespace)
      skip.push namespace
      fqns = find_fully_qualified_namespace(namespace, root)
      return meths if fqns.nil?
      mn = @method_pins[fqns]
      unless mn.nil?
        mn.select{ |pin| pin.scope == :class }.each do |pin|
          meths.push pin.suggestion(self)
        end
      end
      meths.uniq
    end

    def inner_get_instance_methods(namespace, root, skip, visibility = [:public])
      fqns = find_fully_qualified_namespace(namespace, root)
      meths = []
      return meths if skip.include?(fqns)
      skip.push fqns
      an = @attr_nodes[fqns]
      unless an.nil?
        an.each do |pin|
          meths.concat pin.suggestions
        end
      end
      mn = @method_pins[fqns]
      unless mn.nil?
        mn.select{|pin| visibility.include?(pin.visibility) and pin.scope == :instance }.each do |pin|
          meths.push pin.suggestion(self)
        end
      end
      if visibility.include?(:public) or visibility.include?(:protected)
        sc = @superclasses[fqns]
        meths.concat inner_get_instance_methods(sc, fqns, skip, visibility - [:private]) unless sc.nil?
      end
      im = @namespace_includes[fqns]
      unless im.nil?
        im.each do |i|
          meths.concat inner_get_instance_methods(i, fqns, skip, visibility)
        end
      end
      meths.uniq
    end

    def inner_namespaces_in name, root, skip
      result = []
      fqns = find_fully_qualified_namespace(name, root)
      unless fqns.nil? or skip.include?(fqns)
        skip.push fqns
        nodes = get_namespace_nodes(fqns)
        nodes.delete_if { |n| yardoc_has_file?(get_filename_for(n))}
        unless nodes.empty?
          cursor = @namespace_tree
          parts = fqns.split('::')
          parts.each { |p|
            cursor = cursor[p]
          }
          unless cursor.nil?
            cursor.keys.each { |k|
              type = get_namespace_type(k, fqns)
              kind = nil
              detail = nil
              if type == :class
                kind = Suggestion::CLASS
                detail = 'Class'
              elsif type == :module
                kind = Suggestion::MODULE
                detail = 'Module'
              end
              result.push Suggestion.new(k, kind: kind, detail: detail)
            }
            nodes = get_namespace_nodes(fqns)
            nodes.each do |n|
              result.concat get_constant_nodes(n, fqns)
              get_include_strings_from(n).each { |i|
                result += inner_namespaces_in(i, fqns, skip)
              }
            end
          end
        end
      end
      result
    end

    def get_constant_nodes(node, fqns)
      result = []
      node.children.each do |n|
        if n.kind_of?(AST::Node)
          if n.type == :casgn
            cmnt = get_comment_for(n)
            type = infer_assignment_node_type(n, fqns)
            result.push Suggestion.new(n.children[1].to_s, kind: Suggestion::CONSTANT, documentation: cmnt, return_type: type)
          else
            result.concat get_constant_nodes(n, fqns) unless n.type == :class or n.type == :module
          end
        end
      end
      result
    end

    # Get a fully qualified namespace for the given signature.
    # The signature should be in the form of a method chain, e.g.,
    # method1.method2
    #
    # @return [String] The fully qualified namespace for the signature's type
    #   or nil if a type could not be determined
    def inner_infer_signature_type signature, namespace, scope: :instance
      orig = namespace
      namespace = clean_namespace_string(namespace)
      return nil if signature.nil?
      signature.gsub!(/\.$/, '')
      if signature.nil? or signature.empty?
        if scope == :class
          return "#{namespace}#class"
        else
          return "#{namespace}"
        end
      end
      if !namespace.nil? and namespace.end_with?('#class')
        return inner_infer_signature_type signature, namespace[0..-7], scope: (scope == :class ? :instance : :class)
      end
      parts = signature.split('.')
      type = find_fully_qualified_namespace(namespace)
      type ||= ''
      top = true
      while parts.length > 0 and !type.nil?
        p = parts.shift
        next if p.empty?
        next if !type.nil? and !type.empty? and METHODS_RETURNING_SELF.include?(p)
        if top and scope == :class
          if p == 'self'
            top = false
            return "Class<#{type}>" if parts.empty?
            sub = inner_infer_signature_type(parts.join('.'), type, scope: :class)
            return sub unless sub.to_s == ''
            next
          end
          if p == 'new'
            scope = :instance
            type = namespace
            top = false
            next
          end
          first_class = find_fully_qualified_namespace(p, namespace)
          sub = nil
          sub = inner_infer_signature_type(parts.join('.'), first_class, scope: :class) unless first_class.nil?
          return sub unless sub.to_s == ''
        end
        if top and scope == :instance and p == 'self'
          return type if parts.empty?
          sub = infer_signature_type(parts.join('.'), type, scope: :instance)
          return sub unless sub.to_s == ''
        end
        if top and scope == :instance and p == '[]' and !orig.nil?
          if orig.start_with?('Array<')
            match = orig.match(/Array<([a-z0-9:_]*)/i)[1]
            type = match
            next
          end
        end
        unless p == 'new' and scope != :instance
          if scope == :instance
            visibility = [:public]
            visibility.push :private, :protected if top
            meths = get_instance_methods(type, visibility: visibility)
            meths += get_methods('') if top or type.to_s == ''
          else
            meths = get_methods(type)
          end
          meths.delete_if{ |m| m.insert != p }
          return nil if meths.empty?
          type = nil
          match = meths[0].return_type
          unless match.nil?
            cleaned = clean_namespace_string(match)
            if cleaned.end_with?('#class')
              return inner_infer_signature_type(parts.join('.'), cleaned.split('#').first, scope: :class)
            else
              type = find_fully_qualified_namespace(cleaned)
            end
          end
        end
        scope = :instance
        top = false
      end
      type
    end

    def mappable?(node)
      if node.kind_of?(AST::Node) and MAPPABLE_NODES.include?(node.type)
        true
      elsif node.kind_of?(AST::Node) and node.type == :send and node.children[0] == nil and MAPPABLE_METHODS.include?(node.children[1])
        true
      else
        false
      end
    end

    def reduce node, comment_hash
      return node unless node.kind_of?(AST::Node)
      mappable = get_mappable_nodes(node.children, comment_hash)
      result = node.updated nil, mappable
      result
    end

    def get_mappable_nodes arr, comment_hash
      result = []
      arr.each { |n|
        if mappable?(n)
          min = minify(n, comment_hash)
          result.push min
        else
          next unless n.kind_of?(AST::Node)
          result += get_mappable_nodes(n.children, comment_hash)
        end
      }
      result
    end

    def minify node, comment_hash
      return node if node.type == :args
      type = node.type
      children = []
      if node.type == :class or node.type == :block or node.type == :sclass
        children += node.children[0, 2]
        children += get_mappable_nodes(node.children[2..-1], comment_hash)
      elsif node.type == :const or node.type == :args or node.type == :kwargs
        children += node.children
      elsif node.type == :def
        children += node.children[0, 2]
        children += get_mappable_nodes(node.children[2..-1], comment_hash)
      elsif node.type == :defs
        children += node.children[0, 3]
        children += get_mappable_nodes(node.children[3..-1], comment_hash)
      elsif node.type == :module
        children += node.children[0, 1]
        children += get_mappable_nodes(node.children[1..-1], comment_hash)
      elsif node.type == :ivasgn or node.type == :gvasgn or node.type == :lvasgn or node.type == :cvasgn or node.type == :casgn
        children += node.children
      elsif node.type == :send and node.children[1] == :include
        children += node.children[0,3]
      elsif node.type == :send and node.children[1] == :require
        if node.children[2].children[0].kind_of?(String)
          path = node.children[2].children[0].to_s
          @required.push(path) unless local_path?(path)
        end
        children += node.children[0, 3]
      elsif node.type == :send and node.children[1] == :autoload
        @required.push(node.children[3].children[0]) if node.children[3].children[0].kind_of?(String)
        type = :require
        children += node.children[1, 3]
      elsif node.type == :send or node.type == :lvar
        children += node.children
      elsif node.type == :or_asgn
        # TODO: The api_map should ignore local variables.
        type = node.children[0].type
        children.push node.children[0].children[0], node.children[1]
      elsif [:array, :hash, :str, :dstr, :int, :float].include?(node.type)
        # @todo Do we really care about the details?
      elsif node.type == :sym
        children.push node.children[0]
      end
      result = node.updated(type, children)
      result
    end

    def local_path? path
      return false if workspace.nil?
      return true if File.exist?(File.join workspace, 'lib', path)
      return true if File.exist?(File.join workspace, 'lib', "#{path}.rb")
      false
    end

    def map_parents node, tree = []
      if node.kind_of?(AST::Node)
        @parent_stack[node] = tree
        node.children.each { |c|
          map_parents c, [node] + tree
        }
      end
    end

    def add_to_namespace_tree tree
      cursor = @namespace_tree
      tree.each { |t|
        cursor[t.to_s] ||= {}
        cursor = cursor[t.to_s]
      }
    end

    def map_namespaces node, tree = [], visibility = :public, scope = :instance, fqn = nil
      if node.kind_of?(AST::Node)
        return if node.type == :str or node.type == :dstr
        if node.type == :class or node.type == :module
          visibility = :public
          if node.children[0].kind_of?(AST::Node) and node.children[0].children[0].kind_of?(AST::Node) and node.children[0].children[0].type == :cbase
            tree = pack_name(node.children[0])
          else
            tree = tree + pack_name(node.children[0])
          end
          add_to_namespace_tree tree
          fqn = tree.join('::')
          @namespace_map[fqn] ||= []
          @namespace_map[fqn].push node
          if node.type == :class and !node.children[1].nil?
            sc = unpack_name(node.children[1])
            @superclasses[fqn] = sc
          end
        end
        file = get_filename_for(node)
        in_yardoc = yardoc_has_file?(file)
        node.children.each do |c|
          if c.kind_of?(AST::Node)
            if c.type == :ivasgn
              @ivar_pins[fqn || ''] ||= []
              par = find_parent(c, :class, :module, :def, :defs)
              local_scope = ( (par.kind_of?(AST::Node) and par.type == :def) ? :instance : :class )
              @ivar_pins[fqn || ''].push IvarPin.new(self, c, fqn || '', local_scope, get_comment_for(c))
            elsif c.type == :cvasgn
              @cvar_pins[fqn] ||= []
              @cvar_pins[fqn].push CvarPin.new(self, c, fqn, get_comment_for(c))
            elsif c.type == :sym
              @symbol_pins.push SymbolPin.new(c)
            else
              unless fqn.nil? or in_yardoc
                if c.kind_of?(AST::Node)
                  if c.type == :def and c.children[0].to_s[0].match(/[a-z]/i)
                    @method_pins[fqn] ||= []
                    @method_pins[fqn].push MethodPin.new(c, fqn, scope, visibility, get_comment_for(c))
                    map_namespaces c, tree, visibility, scope, fqn
                    next
                  elsif c.type == :defs
                    @method_pins[fqn] ||= []
                    @method_pins[fqn].push MethodPin.new(c, fqn, :class, :public, get_comment_for(c))
                    map_namespaces c, tree, :public, :class, fqn
                    next
                  elsif c.type == :send and [:public, :protected, :private].include?(c.children[1])
                    visibility = c.children[1]
                  elsif c.type == :send and c.children[1] == :include and node.type == :class
                    @namespace_includes[fqn] ||= []
                    @namespace_includes[fqn].push unpack_name(c.children[2])
                  elsif c.type == :send and [:attr_reader, :attr_writer, :attr_accessor].include?(c.children[1])
                    @attr_nodes[fqn] ||= []
                    @attr_nodes[fqn].push AttrPin.new(c)
                  elsif c.type == :sclass and c.children[0].type == :self
                    map_namespaces c, tree, :public, :class, fqn
                    next
                  end
                end
              end
              map_namespaces c, tree, visibility, scope, fqn
            end
          end
        end
      end
    end

    def clean_namespace_string namespace
      result = namespace.to_s.gsub(/<.*$/, '')
      if result == 'Class' and namespace.include?('<')
        subtype = namespace.match(/<([a-z0-9:_]*)/i)[1]
        result = "#{subtype}#class"
      end
      result
    end
  end
end
