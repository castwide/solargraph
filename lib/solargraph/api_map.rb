require 'rubygems'
require 'parser/current'
require 'yard'
require 'yaml'

module Solargraph
  class ApiMap
    autoload :Config, 'solargraph/api_map/config'

    KEYWORDS = [
      '__ENCODING__', '__LINE__', '__FILE__', 'BEGIN', 'END', 'alias', 'and',
      'begin', 'break', 'case', 'class', 'def', 'defined?', 'do', 'else',
      'elsif', 'end', 'ensure', 'false', 'for', 'if', 'in', 'module', 'next',
      'nil', 'not', 'or', 'redo', 'rescue', 'retry', 'return', 'self', 'super',
      'then', 'true', 'undef', 'unless', 'until', 'when', 'while', 'yield'
    ].freeze

    MAPPABLE_NODES = [
      # @todo Add node.type :casgn (constant assignment)
      :array, :hash, :str, :int, :float, :block, :class, :module, :def, :defs,
      :ivasgn, :gvasgn, :lvasgn, :cvasgn, :or_asgn, :const, :lvar, :args, :kwargs
    ].freeze

    MAPPABLE_METHODS = [
      :include, :extend, :require, :autoload, :attr_reader, :attr_writer,
      :attr_accessor, :private, :public, :protected
    ].freeze

    include NodeMethods

    attr_reader :workspace
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

    def clear
      @file_source = {}
      @file_nodes = {}
      @file_comments = {}
      @parent_stack = {}
      @namespace_map = {}
      @namespace_tree = {}
      @required = []
    end

    # @return [Solargraph::YardMap]
    def yard_map
      @yard_map ||= YardMap.new(required: required, workspace: workspace)
    end

    # @param filename [String]
    def append_file filename
      append_source File.read(filename), filename
    end

    # @param text [String]
    # @param filename [String]
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

    def append_node node, comments, filename = nil
      @file_comments[filename] = associate_comments(node, comments)
      mapified = reduce(node, @file_comments[filename])
      root = AST::Node.new(:begin, [filename])
      root = root.append mapified
      @file_nodes[filename] = root
      @required.uniq!
      process_maps
      root
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

    def get_comment_for node
      filename = get_filename_for(node)
      return nil if @file_comments[filename].nil?
      @file_comments[filename][node.loc]
    end

    def self.get_keywords
      result = []
      keywords = KEYWORDS + ['attr_reader', 'attr_writer', 'attr_accessor', 'private', 'public', 'protected']
      keywords.each { |k|
        result.push Suggestion.new(k, kind: Suggestion::KEYWORD, detail: 'Keyword')
      }
      result
    end

    def process_maps
      @parent_stack = {}
      @namespace_map = {}
      @namespace_tree = {}
      @file_nodes.values.each { |f|
        map_parents f
        map_namespaces f
      }
    end

    def namespaces
      @namespace_map.keys
    end

    def namespace_exists? name, root = ''
      !find_fully_qualified_namespace(name, root).nil?
    end

    def namespaces_in name, root = ''
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
      @namespace_map[fqns] || []
    end

    def get_instance_variables(namespace, scope = :instance)
      nodes = get_namespace_nodes(namespace) || @file_nodes.values
      arr = []
      nodes.each { |n|
        arr += inner_get_instance_variables(n, scope)
      }
      arr
    end

    def get_class_variables(namespace)
      nodes = get_namespace_nodes(namespace) || @file_nodes.values
      arr = []
      nodes.each { |n|
        arr += inner_get_class_variables(n)
      }
      arr
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

    def infer_instance_variable(var, namespace, scope = :instance)
      result = nil
      vn = nil
      fqns = find_fully_qualified_namespace(namespace)
      unless fqns.nil?
        get_namespace_nodes(fqns).each { |node|
          vn = find_instance_variable_assignment(var, node, scope)
          break unless vn.nil?
        }
      end
      unless vn.nil?
        cmnt = get_comment_for(vn)
        unless cmnt.nil?
          tag = cmnt.tag(:type)
          result = tag.types[0] unless tag.nil? or tag.types.empty?
        end
        result = infer(vn.children[1]) if result.nil?
        if result.nil?
          signature = resolve_node_signature(vn.children[1])
          sig_ns = find_fully_qualified_namespace(signature.split('.').first, fqns)
          sig_scope = (sig_ns.nil? ? :instance : :class)
          result = infer_signature_type(signature, namespace, scope: sig_scope)
        end
      end
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
        result = infer(vn.children[1]) if result.nil?
        if result.nil?
          signature = resolve_node_signature(vn.children[1])
          sig_ns = find_fully_qualified_namespace(signature.split('.').first, fqns)
          sig_scope = (sig_ns.nil? ? :instance : :class)
          result = infer_signature_type(signature, namespace, scope: sig_scope)
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

    # Get a fully qualified namespace for the given signature.
    # The signature should be in the form of a method chain, e.g.,
    # method1.method2
    #
    # @return [String] The fully qualified namespace for the signature's type
    #   or nil if a type could not be determined
    def infer_signature_type signature, namespace, scope: :instance
      parts = signature.split('.')
      type = find_fully_qualified_namespace(namespace)
      type ||= ''
      top = true
      while parts.length > 0 and !type.nil?
        p = parts.shift
        if top and scope == :class
          next if p == 'new'
          first_class = find_fully_qualified_namespace(p, namespace)
          sub = nil
          sub = infer_signature_type(parts.join('.'), first_class, scope: :class) unless first_class.nil?
          return sub unless sub.to_s == ''
        end
        unless p == 'new' and scope != :instance
          if scope == :instance
            meths = get_instance_methods(type)
            meths += get_methods('') if top or type.to_s == ''
          else
            meths = get_methods(type)
          end
          meths.delete_if{ |m| m.insert != p }
          return nil if meths.empty?
          type = nil
          match = meths[0].return_type
          type = find_fully_qualified_namespace(match) unless match.nil?
        end
        scope = :instance
        top = false
      end
      type
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

    def get_method_args node
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
          args.push c.children[0]
        elsif c.type == :optarg
          args.push "#{c.children[0]} = #{code_for(c.children[1])}"
        elsif c.type == :kwarg
          args.push "#{c.children[0]}:"
        elsif c.type == :kwoptarg
          args.push "#{c.children[0]}: #{code_for(c.children[1])}"
        end
      }
      args
    end

    # Get an array of instance methods that are available in the specified
    # namespace.
    #
    # @return [Array<Solargraph::Suggestion>]
    def get_instance_methods(namespace, root = '', visibility: [:public])
      meths = []
      meths += inner_get_instance_methods(namespace, root, []) #unless has_yardoc?
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
    
    # Update the YARD documentation for the current workspace.
    #
    def update_yardoc
      if workspace.nil?
        STDERR.puts "No workspace specified for yardoc update."
      else
        Thread.new do
          Dir.chdir(workspace) do
            STDERR.puts "Updating the yardoc for #{workspace}..."
            cmd = "yardoc -e #{Solargraph::YARD_EXTENSION_FILE}"
            STDERR.puts "Update yardoc with #{cmd}"
            STDERR.puts `#{cmd}`
            unless $?.success?
              STDERR.puts "There was an error processing the workspace yardoc."
            end
          end
        end
      end
    end

    private

    def inner_get_methods(namespace, root = '', skip = [])
      meths = []
      return meths if skip.include?(namespace)
      skip.push namespace
      fqns = find_fully_qualified_namespace(namespace, root)
      return meths if fqns.nil?
      nodes = get_namespace_nodes(fqns)
      nodes.each { |n|
        unless yardoc_has_file?(get_filename_for(n))
          if n.kind_of?(AST::Node)
            if n.type == :class and !n.children[1].nil?
              s = unpack_name(n.children[1])
              meths += inner_get_methods(s, root, skip)
            end
            meths += inner_get_methods_from_node(n, root, skip)
          end
        end
      }
      meths.uniq
    end

    def inner_get_methods_from_node node, root, skip
      meths = []
      node.children.each { |c|
        if c.kind_of?(AST::Node)
          if c.type == :defs
            docstring = get_comment_for(c)
            label = "#{c.children[1]}"
            args = get_method_args(c)
            if (c.children[1].to_s[0].match(/[a-z_]/i) and c.children[1] != :def)
              meths.push Suggestion.new(label, insert: c.children[1].to_s.gsub(/=/, ' = '), kind: Suggestion::METHOD, detail: 'Method', documentation: docstring, arguments: args)
            end
          elsif c.type == :send and c.children[1] == :include
            # TODO: This might not be right. Should we be getting singleton methods
            # from an include, or only from an extend?
            i = unpack_name(c.children[2])
            meths.concat inner_get_methods(i, root, skip) unless i == 'Kernel'
          else
            meths.concat inner_get_methods_from_node(c, root, skip)
          end
        end
      }
      meths
    end

    def inner_get_instance_methods(namespace, root, skip)
      fqns = find_fully_qualified_namespace(namespace, root)
      meths = []
      return meths if skip.include?(fqns)
      skip.push fqns
      nodes = get_namespace_nodes(fqns)
      nodes.each { |n|
        f = get_filename_for(n)
        unless yardoc_has_file?(get_filename_for(n))
          if n.kind_of?(AST::Node)
            if n.type == :class and !n.children[1].nil?
              s = unpack_name(n.children[1])
              # @todo This skip might not work properly. We might need to get a
              #   fully qualified namespace from it first
              meths += get_instance_methods(s, namespace) unless skip.include?(s)
            end
            current_scope = :public
            n.children.each { |c|
              if c.kind_of?(AST::Node) and c.type == :send and [:public, :protected, :private].include?(c.children[1])
              # TODO: Determine the current scope so we can decide whether to
              # exclude protected or private methods. Right now we're just
              # assuming public only
              elsif c.kind_of?(AST::Node) and c.type == :send and c.children[1] == :include
                fqmod = find_fully_qualified_namespace(const_from(c.children[2]), root)
                meths += get_instance_methods(fqmod) unless fqmod.nil? or skip.include?(fqmod)
              elsif current_scope == :public
                if c.kind_of?(AST::Node) and c.type == :def
                  cmnt = get_comment_for(c)
                  label = "#{c.children[0]}"
                  args = get_method_args(c)
                  meths.push Suggestion.new(label, insert: c.children[0].to_s.gsub(/=/, ' = '), kind: Suggestion::METHOD, documentation: cmnt, detail: fqns, arguments: args) if c.children[0].to_s[0].match(/[a-z]/i)
                elsif c.kind_of?(AST::Node) and c.type == :send and c.children[1] == :attr_reader
                  c.children[2..-1].each { |x|
                    meths.push Suggestion.new(x.children[0], kind: Suggestion::FIELD) if x.type == :sym
                  }
                elsif c.kind_of?(AST::Node) and c.type == :send and c.children[1] == :attr_writer
                  c.children[2..-1].each { |x|
                    meths.push Suggestion.new("#{x.children[0]}=", kind: Suggestion::FIELD) if x.type == :sym
                  }
                elsif c.kind_of?(AST::Node) and c.type == :send and c.children[1] == :attr_accessor
                  c.children[2..-1].each { |x|
                    meths.push Suggestion.new(x.children[0], kind: Suggestion::FIELD) if x.type == :sym
                    meths.push Suggestion.new("#{x.children[0]}=", kind: Suggestion::FIELD) if x.type == :sym
                  }
                end
              end
            }
          end
        end
        # This is necessary to get included modules from workspace definitions
        get_include_strings_from(n).each { |i|
          meths += inner_get_instance_methods(i, fqns, skip)
        }
      }
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
            nodes.each { |n|
              get_include_strings_from(n).each { |i|
                result += inner_namespaces_in(i, fqns, skip)
              }
            }
          end
        end
      end
      result
    end

    def inner_get_instance_variables(node, scope)
      arr = []
      if node.kind_of?(AST::Node)
        node.children.each { |c|
          if c.kind_of?(AST::Node)
            is_inst = !find_parent(c, :def).nil?
            if c.type == :ivasgn and c.children[0] and ( (scope == :instance and is_inst) or (scope != :instance and !is_inst) )
              arr.push Suggestion.new(c.children[0], kind: Suggestion::VARIABLE, documentation: get_comment_for(c))
            end
            arr += inner_get_instance_variables(c, scope) unless [:class, :module].include?(c.type)
          end
        }
      end
      arr
    end

    def inner_get_class_variables(node)
      arr = []
      if node.kind_of?(AST::Node)
        node.children.each { |c|
          next unless c.kind_of?(AST::Node)
          if c.type == :cvasgn
            arr.push Suggestion.new(c.children[0], kind: Suggestion::VARIABLE, documentation: get_comment_for(c))              
          end
          arr += inner_get_class_variables(c) unless [:class, :module].include?(c.type)
        }
      end
      arr
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
      if node.type == :class or node.type == :block
        children += node.children[0, 2]
        children += get_mappable_nodes(node.children[2..-1], comment_hash)
        #children += get_mappable_nodes(node.children, comment_hash)
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
      elsif node.type == :ivasgn or node.type == :gvasgn or node.type == :lvasgn or node.type == :cvasgn
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
      elsif [:array, :hash, :str, :int, :float].include?(node.type)
        # @todo Do we really care about the details?
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

    def map_namespaces node, tree = []
      if node.kind_of?(AST::Node)
        if node.type == :class or node.type == :module
          if node.children[0].kind_of?(AST::Node) and node.children[0].children[0].kind_of?(AST::Node) and node.children[0].children[0].type == :cbase
            tree = pack_name(node.children[0])
          else
            tree = tree + pack_name(node.children[0])
          end
          add_to_namespace_tree tree
          fqn = tree.join('::')
          @namespace_map[fqn] ||= []
          @namespace_map[fqn].push node
        end
        node.children.each { |c|
          map_namespaces c, tree
        }
      end
    end

    def code_for node
      src = @file_source[get_filename_for(node)]
      return nil if src.nil?
      b = node.location.expression.begin.begin_pos
      e = node.location.expression.end.end_pos
      src[b..e].strip.gsub(/,$/, '')
    end
  end
end
