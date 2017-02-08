$LOAD_PATH.unshift '/home/fred/gamefic/lib'

require 'parser/current'

module Solargraph
  class ApiMap
    KEYWORDS = [
      '__ENCODING__', '__LINE__', '__FILE__', 'BEGIN', 'END', 'alias', 'and',
      'begin', 'break', 'case', 'class', 'def', 'defined?', 'do', 'else',
      'elsif', 'end', 'ensure', 'false', 'for', 'if', 'in', 'module', 'next',
      'nil', 'not', 'or', 'redo', 'rescue', 'retry', 'return', 'self', 'super',
      'then', 'true', 'undef', 'unless', 'until', 'when', 'while', 'yield'
    ]
    
    MAPPABLE_METHODS = [
      :include, :require, :attr_reader, :attr_writer, :attr_accessor
    ]
    include NodeMethods
    
    attr_reader :node
    
    def initialize
      @node = AST::Node.new(:begin, [])
      @parent_stack = {}
      @namespace_map = {}
      @namespace_tree = {}
      @pending_requires = []
      @merged_requires = []
    end

    def dup
      other = ApiMap.new
      other.merge @node
      other
    end

    def merge node
      return if node.nil?
      mapified = mapify(node)
      mapified.children.each { |c|
        @node = inner_merge c, @node
      }
      run_requires
      process_maps
    end
    
    def process_maps
      @parent_stack = {}
      @namespace_map = {}
      @namespace_tree = {}
      map_parents @node
      map_namespaces @node
    end
    
    def run_requires
      while r = @pending_requires.shift
        parse_require r
      end
    end
    
    def parse_require name
      return if @merged_requires.include?(name)
      @merged_requires.push name
      $LOAD_PATH.each { |p|
        if File.exist?("#{p}/#{name}.rb")
          c = File.read("#{p}/#{name}.rb")
          n = Parser::CurrentRuby.parse(c)
          quick_merge n
          return
        end
      }
      f = "#{Solargraph::STUB_PATH}/ruby/#{RUBY_VERSION}/stdlib/#{name}.rb"
      if File.exist?(f)
        c = File.read(f)
        n = Parser::CurrentRuby.parse(c)
        quick_merge n
        return
      end
      spec = Gem::Specification.find_by_name(name.split('/')[0])
      gem_root = spec.gem_dir
      gem_lib = gem_root + "/lib"
      f = "#{gem_lib}/#{name}.rb"
      if File.exist?(f)
        c = File.read(f)
        n = Parser::CurrentRuby.parse(c)
        quick_merge n
        return
      end
      puts "Required lib not found: #{name}"
    end
    
    def quick_merge node
        m = mapify(node)
        m.children.each { |c|
          @node = inner_merge c, @node
        }    
    end
    
    def namespaces
      @namespace_map.keys
    end
    
    def namespace_exists? name, root = ''
      @namespace_map.keys.include?(name)
    end
    
    # Get all namespaces that are direct descendants of the specified namespace.
    #
    # @return [Array<String>]
    def namespaces_in name, root = ''
      inner_namespaces_in name, root, []
    end
    
    def inner_namespaces_in name, root, skip
      result = []
      fqns = find_fully_qualified_namespace(name, root)
      STDERR.puts "#{name}, #{root} goes to #{fqns}"
      STDERR.puts "WTF? skipping #{fqns}" if skip.include?(fqns)
      unless fqns.nil? or skip.include?(fqns)
        skip.push(fqns)
        cursor = @namespace_tree
        parts = fqns.split('::')
        STDERR.puts "Gonna use #{parts.length} parts"
        parts.each { |p|
          STDERR.puts "For #{p} doin shit"
          cursor = cursor[p]
        }
        STDERR.puts "Cursor: #{cursor}"
        unless cursor.nil?
          result += cursor.keys
          #skip += cursor.keys
          nodes = get_namespace_nodes(fqns)
          nodes.each { |n|
            get_includes_from(n).each { |i|
              n = unpack_name(i.children[2])
              STDERR.puts "Looking in #{n}"
              result += inner_namespaces_in(n, fqns, skip)
            }
          }
        end
      end
      result    
    end
    
    def find_fully_qualified_namespace name, root = ''
      if name == ''
        return '' if root == ''
        return @namespace_map[root].nil? ? nil : root
      elsif root == ''
        return @namespace_map[name].nil? ? nil : name
      else
        roots = root.split('::')
        while roots.length > 0
          fqns = roots.join('::') + '::' + name
          STDERR.puts "Checking #{fqns}"
          return fqns unless @namespace_map[fqns].nil?
          roots.pop
        end
        return name unless @namespace_map[fqns].nil?
      end
      STDERR.puts "Nothing found for #{name}, #{root}"
      nil
    end

    def get_namespace_nodes(fqns)
      return [@node] if fqns == ''
      @namespace_map[fqns] || []
    end
    
    def get_instance_variables(namespace, scope = :instance)
      nodes = get_namespace_nodes(namespace) || [@node]
      arr = []
      nodes.each { |n|
        arr += inner_get_instance_variables(n, scope)
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
    
    def inner_get_instance_variables(node, scope)
      arr = []
      node.children.each { |c|
        if c.kind_of?(AST::Node)
          is_inst = !find_parent(c, :def).nil?
          if c.type == :ivasgn and ( (scope == :instance and is_inst) or (scope != :instance and !is_inst) )
            arr.push c.children[0]
          end
          arr += inner_get_instance_variables(c, scope)
        end
      }
      arr
    end
    
    def get_global_variables
      # TODO I bet these aren't getting mapped at all. Damn.
      []
    end
    
    def get_methods(namespace, root = '', skip = [])
      meths = []
      return meths if skip.include?(namespace)
      skip.push namespace
      fqns = find_fully_qualified_namespace(namespace, root)
      nodes = get_namespace_nodes(fqns)
      unless nodes.nil?
        nodes.each { |n|
          if n.type == :class and !n.children[1].nil?
            s = unpack_name(n.children[1])
            meths += get_methods(s, root, skip)
          end
          n.children.each { |c|
            if c.kind_of?(AST::Node) and c.type == :defs
              meths.push c.children[1] if c.children[1].to_s[0].match(/[a-z]/i)
            elsif c.kind_of?(AST::Node) and c.type == :send and c.children[1] == :include
              # TODO This might not be right. Should we be getting singleton methods
              # from an include, or only from an extend?
              i = unpack_name(c.children[2])
              meths += get_methods(i, root, skip) unless i == 'Kernel'
            end
          }
        }
      end
      meths += get_methods('BasicObject', root, skip) if !nodes.nil? and nodes[0].kind_of?(AST::Node) and nodes[0].type == :class
      meths.uniq
    end
    
    def get_instance_methods(namespace, root = '', skip = [])
      fqns = find_fully_qualified_namespace(namespace, root)
      meths = []
      if fqns.nil?
        STDERR.puts "Failed to find fully qualified namespace for '#{namespace}' from '#{root}'"
        return meths
      end
      return meths if skip.include?(fqns)
      skip.push fqns
      nodes = get_namespace_nodes(fqns)
      STDERR.puts "Namespace nodes found: #{nodes.length}"
      nodes.each { |n|
        if n.type == :class and !n.children[1].nil?
          s = unpack_name(n.children[1])
          meths += get_instance_methods(s, namespace, skip)
        end
        n.children.each { |c|
          if c.kind_of?(AST::Node) and c.type == :def
            meths.push c.children[0] if c.children[0].to_s[0].match(/[a-z]/i)
          elsif c.kind_of?(AST::Node) and c.type == :send and c.children[1] == :attr_reader
            c.children[2..-1].each { |x|
              meths.push x.children[0] if x.type == :sym
            }
          elsif c.kind_of?(AST::Node) and c.type == :send and c.children[1] == :attr_writer
            c.children[2..-1].each { |x|
              meths.push "#{x.children[0]}=" if x.type == :sym
            }
          elsif c.kind_of?(AST::Node) and c.type == :send and c.children[1] == :attr_accessor
            meths.concat c.children[2..-1]
            c.children[2..-1].each { |x|
              meths.push x.children[0] if x.type == :sym
              meths.push "#{x.children[0]}=" if x.type == :sym
            }
          elsif c.kind_of?(AST::Node) and c.type == :send and c.children[1] == :include
            i = unpack_name(c.children[2])
            STDERR.puts "Gonna try to get methods from included module #{i}"
            meths += get_instance_methods(i, fqns, skip) unless i == 'Kernel'
          end
        }
      }
      meths += get_instance_methods('BasicObject', root, skip) if nodes.length > 0 and nodes[0].type == :class
      meths.uniq
    end
    
    def self.current
      #map = ApiMap.new
      #map.merge(Parser::CurrentRuby.parse(File.read("#{Solargraph::STUB_PATH}/ruby/#{RUBY_VERSION}/core.rb")))
      #map
      #Marshal.load(File.read("#{Solargraph::STUB_PATH}/ruby/#{RUBY_VERSION}/core.ser"))
      if @current.nil?
        @current = ApiMap.new
        @current.merge(Parser::CurrentRuby.parse(File.read("#{Solargraph::STUB_PATH}/ruby/2.3.0/core.rb")))
      end
      @current
    end
    
    def get_descendants node, *types
      arr = []
      node.children.each { |n|
        if n.kind_of?(AST::Node)
          arr.push n if types.include?(n.type)
          arr += get_descendants(n, *types)
        end
      }
      arr
    end
    
    def get_includes_from node
      arr = []
      node.children.each { |n|
        if n.kind_of?(AST::Node)
          arr.push n if (n.type == :send and n.children[1] == :include)
          arr += get_includes_from(n) if n.type != :class and n.type != :module
        end
      }
      arr
    end
    
    private
    
    def inner_merge src, dst
      return dst unless src.kind_of?(AST::Node)
      result = dst
      if mappable?(src)
        match = find_match(src, dst.children)
        if match.nil?
          # Append to result
          result = result.append(src)
        else
          merged = match
          src.children.each { |c|
            merged = inner_merge(c, merged)
          }
          result = result.updated(nil, result.children - [match] + [merged])
        end
      else
        src.children.each { |c|
          result = inner_merge c, result
        }
      end
      result
    end
    
    def find_match src, nodes
      nodes.each { |n|
        # For most nodes, we can assume a match if they have equivalent first
        # children. That's enough to identify distinct class, modules, and
        # methods. If the node is a :send or a variable assignment, we assume
        # it's unique.
        return n if n.kind_of?(AST::Node) and n.children[0] == src.children[0] and n.type != :send and n.type != :ivasgn and n.type != :gvasgn
      }
      nil
    end
    
    def mapify node
      root = node
      if root.type != :begin
        root = AST::Node.new(:begin, [node], {})
      end
      root = reduce root
      root
    end
    
    def mappable?(node)
      # TODO Add node.type :casgn (constant assignment)
      if node.kind_of?(AST::Node) and (node.type == :class or node.type == :module or node.type == :def or node.type == :defs or node.type == :ivasgn or node.type == :gvasgn)
        true
      elsif node.kind_of?(AST::Node) and node.type == :send and node.children[0] == nil and MAPPABLE_METHODS.include?(node.children[1])
        true
      else
        false
      end
    end
    
    def reduce node
      mappable = get_mappable_nodes(node.children)
      node.updated nil, mappable
    end
    
    def get_mappable_nodes arr
      result = []
      arr.each { |n|
        if mappable?(n)
          min = minify(n)
          result.push min
        else
          next unless n.kind_of?(AST::Node)
          result += get_mappable_nodes(n.children)
        end
      }
      result
    end
    
    def minify node
      return node if node.type == :args
      type = node.type
      children = []
      if node.type == :class
        children += node.children[0, 2]
        children += get_mappable_nodes(node.children[2..-1])
      elsif node.type == :def
        children += node.children[0, 2]
        children += get_mappable_nodes(node.children[2..-1])
      elsif node.type == :defs
        children += node.children[0, 3]
        children += get_mappable_nodes(node.children[3..-1])
      elsif node.type == :module
        children += node.children[0, 1]
        children += get_mappable_nodes(node.children[1..-1])
      elsif node.type == :ivasgn or node.type == :gvasgn
        children += node.children[0, 1]
        children += get_mappable_nodes(node.children[1..-1])
      elsif node.type == :send and node.children[1] == :include
        children += node.children[0,3]
        #children += get_mappable_nodes(node.children[3..-1])
      elsif node.type == :send and node.children[1] == :require
        @pending_requires.push(node.children[2].children[0])
        children += node.children[0, 3]
      elsif node.type == :send #and node.children[1] == :require
        children += node.children
      end
      AST::Node.new(type, children)
    end
    
    def map_parents node, tree = []
      if node.kind_of?(AST::Node) #and (node.type == :class or node.type == :module)
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
          if node.children[0].children[0].kind_of?(AST::Node) and node.children[0].children[0].type == :cbase
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
  end
end
