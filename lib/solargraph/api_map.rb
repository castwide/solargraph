require 'rubygems'
require 'parser/current'
require 'thread'

module Solargraph
  class ApiMap
    autoload :Config,    'solargraph/api_map/config'
    autoload :Source,    'solargraph/api_map/source'
    autoload :Cache,     'solargraph/api_map/cache'

    @@source_cache = {}

    KEYWORDS = [
      '__ENCODING__', '__LINE__', '__FILE__', 'BEGIN', 'END', 'alias', 'and',
      'begin', 'break', 'case', 'class', 'def', 'defined?', 'do', 'else',
      'elsif', 'end', 'ensure', 'false', 'for', 'if', 'in', 'module', 'next',
      'nil', 'not', 'or', 'redo', 'rescue', 'retry', 'return', 'self', 'super',
      'then', 'true', 'undef', 'unless', 'until', 'when', 'while', 'yield'
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
      @workspace_files = []
      unless @workspace.nil?
        config = ApiMap::Config.new(@workspace)
        @workspace_files.concat (config.included - config.excluded)
        @workspace_files.each do |wf|
          begin
            @@source_cache[wf] ||= Source.load(wf)
          rescue
            STDERR.puts "Failed to load #{wf}"
          end
        end
      end
      @sources = {}
      @virtual_source = nil
      @virtual_filename = nil
      @stale = true
      refresh
    end

    # @return [Solargraph::YardMap]
    def yard_map
      refresh
      if @yard_map.nil? || @yard_map.required != required
        @yard_map = Solargraph::YardMap.new(required: required, workspace: workspace)
      end
      @yard_map
    end

    def virtualize filename, code, cursor = nil
      refresh
      @virtual_filename = filename
      @virtual_source = Source.fix(filename, code, cursor)
      process_virtual
      @virtual_source
    end

    def append_source code, filename
      virtualize filename, code
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
      return nil if @sources[filename].nil?
      @sources[filename].docstring_for(node)
    end

    # @return [Array<Solargraph::Suggestion>]
    def self.get_keywords
      @keyword_suggestions ||= KEYWORDS.map{ |s|
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
      result
    end

    def get_constant_pins namespace, root
      fqns = find_fully_qualified_namespace(namespace, root)
      @const_pins[fqns] || []
    end

    def get_constants namespace, root
      result = []
      fqns = find_fully_qualified_namespace(namespace, root)
      cp = @const_pins[fqns]
      unless cp.nil?
        cp.each do |pin|
          result.push pin_to_suggestion(pin)
        end
      end
      result.concat yard_map.get_constants(namespace, root)
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
          get_include_strings_from(*file_nodes).each { |i|
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
          get_include_strings_from(*file_nodes).each { |i|
            recname = find_fully_qualified_namespace name, i, skip
            return recname unless recname.nil?
          }
        end
      end
      yard_map.find_fully_qualified_namespace(name, root)
    end

    def get_namespace_nodes(fqns)
      return file_nodes if fqns == '' or fqns.nil?
      refresh
      @namespace_map[fqns] || []
    end

    def get_instance_variable_pins(namespace, scope = :instance)
      refresh
      (@ivar_pins[namespace] || []).select{ |pin| pin.scope == scope }
    end

    def get_instance_variables(namespace, scope = :instance)
      refresh
      result = []
      ip = @ivar_pins[namespace]
      unless ip.nil?
        ip.select{ |pin| pin.scope == scope }.each do |pin|
          result.push pin_to_suggestion(pin)
        end
      end
      result
    end

    def get_class_variable_pins(namespace)
      refresh
      @cvar_pins[namespace] || []
    end

    def get_class_variables(namespace)
      refresh
      result = []
      ip = @cvar_pins[namespace]
      unless ip.nil?
        ip.each do |pin|
          result.push pin_to_suggestion(pin)
        end
      end
      result
    end

    def get_symbols
      refresh
      @symbol_pins.uniq(&:label)
    end

    def get_filename_for(node)
      @sources.each do |filename, source|
        return source.filename if source.include?(node)
      end
      nil
    end

    def infer_instance_variable(var, namespace, scope)
      refresh
      pins = @ivar_pins[namespace]
      return nil if pins.nil?
      pin = pins.select{|p| p.name == var and p.scope == scope}.first
      return nil if pin.nil?
      pin.return_type
    end

    def infer_class_variable(var, namespace)
      refresh
      fqns = find_fully_qualified_namespace(namespace)
      pins = @cvar_pins[fqns]
      return nil if pins.nil?
      pin = pins.select{|p| p.name == var}.first
      return nil if pin.nil?
      pin.return_type
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
      if cache.has_signature_type?(signature, namespace, scope)
        return cache.get_signature_type(signature, namespace, scope)
      end
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
      meths.concat inner_get_methods(namespace, root, []) #unless has_yardoc?
      yard_meths = yard_map.get_methods(namespace, root, visibility: visibility)
      if yard_meths.any?
        meths.concat yard_meths
      else
        type = get_namespace_type(namespace, root)
        if type == :class
          meths.concat yard_map.get_instance_methods('Class')
        elsif type == :module
          meths.concat yard_map.get_methods('Module')
        end
      end
      news = meths.select{|s| s.label == 'new'}
      unless news.empty?
        fqns = find_fully_qualified_namespace(namespace, root)
        if @method_pins[fqns]
          inits = @method_pins[fqns].select{|p| p.name == 'initialize'}
          meths -= news unless inits.empty?
          inits.each do |pin|
            meths.push Suggestion.new('new', kind: pin.kind, documentation: pin.docstring, detail: pin.namespace, arguments: pin.parameters, path: pin.path)
          end
        end
      end
      meths
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

    def update filename
      @@source_cache[filename] ||= Source.load(filename)
      cache.clear
    end

    def sources
      @sources.values
    end

    def get_path_suggestions path
      result = []
      if path.include?('#')
        # It's an instance method
        parts = path.split('#')
        result = get_instance_methods(parts[0], '', visibility: [:public, :private, :protected]).select{|s| s.label == parts[1]}
      elsif path.include?('.')
        # It's a class method
        parts = path.split('.')
        result = get_instance_methods(parts[0], '', visibility: [:public, :private, :protected]).select{|s| s.label == parts[1]}
      else
        # It's a class or module
        get_namespace_nodes(path).each do |node|
          # TODO This is way underimplemented
          result.push Suggestion.new(path, kind: Suggestion::CLASS)
        end
        result.concat yard_map.objects(path)
      end
      result
    end

    private

    def clear
      @stale = false
      @parent_stack = {}
      @namespace_map = {}
      @namespace_tree = {}
      @required = []
    end

    def process_maps
      @sources.clear
      @workspace_files.each do |f|
        begin
          @@source_cache[f] ||= Source.load(f)
          @sources[f] = @@source_cache[f]
        rescue
          STDERR.puts "Failed to load #{f}"
        end
      end
      cache.clear
      @ivar_pins = {}
      @cvar_pins = {}
      @const_pins = {}
      @method_pins = {}
      @symbol_pins = []
      @attr_pins = {}
      @namespace_includes = {}
      @superclasses = {}
      @parent_stack = {}
      @namespace_map = {}
      @namespace_tree = {}
      @required = []
      @pin_suggestions = {}
      unless @virtual_source.nil?
        @sources[@virtual_filename] = @virtual_source
      end
      @sources.values.each do |s|
        s.namespace_nodes.each_pair do |k, v|
          @namespace_map[k] ||= []
          @namespace_map[k].concat v
          add_to_namespace_tree k.split('::')
        end
      end
      @sources.values.each { |s|
        map_source s
      }
      @required.uniq!
      @stale = false
    end

    def process_virtual
      unless @virtual_source.nil?
        cache.clear
        @sources[@virtual_filename] = @virtual_source
        @sources.values.each do |s|
          s.namespace_nodes.each_pair do |k, v|
            @namespace_map[k] ||= []
            @namespace_map[k].concat v
            add_to_namespace_tree k.split('::')
          end
        end
        [@ivar_pins.values, @cvar_pins.values, @const_pins.values, @method_pins.values, @attr_pins.values].each do |pinsets|
          pinsets.each do |pins|
            pins.delete_if{|pin| pin.filename == @virtual_filename}
          end
        end
        #@symbol_pins.delete_if{|pin| pin.filename == @virtual_filename}
        map_source @virtual_source
      end
    end

    # @param [Solargraph::ApiMap::Source]
    def map_source source
      source.method_pins.each do |pin|
        @method_pins[pin.namespace] ||= []
        @method_pins[pin.namespace].push pin
      end
      source.attribute_pins.each do |pin|
        @attr_pins[pin.namespace] ||= []
        @attr_pins[pin.namespace].push pin
      end
      source.instance_variable_pins.each do |pin|
        @ivar_pins[pin.namespace] ||= []
        @ivar_pins[pin.namespace].push pin
      end
      source.class_variable_pins.each do |pin|
        @cvar_pins[pin.namespace] ||= []
        @cvar_pins[pin.namespace].push pin
      end
      source.constant_pins.each do |pin|
        @const_pins[pin.namespace] ||= []
        @const_pins[pin.namespace].push pin
      end
      source.symbol_pins.each do |pin|
        @symbol_pins.push Suggestion.new(pin.name, kind: Suggestion::CONSTANT, return_type: 'Symbol')
      end
      source.namespace_includes.each_pair do |ns, i|
        @namespace_includes[ns] ||= []
        @namespace_includes[ns].concat(i).uniq!
      end
      source.superclasses.each_pair do |cls, sup|
        @superclasses[cls] = sup
      end
      source.required.each do |r|
        required.push r
      end
    end

    # @return [Solargraph::ApiMap::Cache]
    def cache
      @cache ||= Cache.new
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
          meths.push pin_to_suggestion(pin)
        end
      end
      meths.uniq
    end

    def inner_get_instance_methods(namespace, root, skip, visibility = [:public])
      fqns = find_fully_qualified_namespace(namespace, root)
      meths = []
      return meths if skip.include?(fqns)
      skip.push fqns
      an = @attr_pins[fqns]
      unless an.nil?
        an.each do |pin|
          meths.push pin_to_suggestion(pin)
        end
      end
      mn = @method_pins[fqns]
      unless mn.nil?
        mn.select{|pin| visibility.include?(pin.visibility) and pin.scope == :instance }.each do |pin|
          meths.push pin_to_suggestion(pin)
        end
      end
      if visibility.include?(:public) or visibility.include?(:protected)
        sc = @superclasses[fqns]
        unless sc.nil?
          meths.concat inner_get_instance_methods(sc, fqns, skip, visibility - [:private])
          meths.concat yard_map.get_instance_methods(sc, fqns, visibility: visibility - [:private])
        end
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
            cp = @const_pins[fqns]
            unless cp.nil?
              cp.each do |pin|
                result.push pin_to_suggestion(pin)
              end
            end
            inc = @namespace_includes[fqns]
            unless inc.nil?
              inc.each do |i|
                result.concat inner_namespaces_in(i, fqns, skip)
              end
            end
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

    def add_to_namespace_tree tree
      cursor = @namespace_tree
      tree.each { |t|
        cursor[t.to_s] ||= {}
        cursor = cursor[t.to_s]
      }
    end

    def file_nodes
      @sources.values.map(&:node)
    end

    def clean_namespace_string namespace
      result = namespace.to_s.gsub(/<.*$/, '')
      if result == 'Class' and namespace.include?('<')
        subtype = namespace.match(/<([a-z0-9:_]*)/i)[1]
        result = "#{subtype}#class"
      end
      result
    end

    def pin_to_suggestion pin
      #@pin_suggestions[pin] ||= Suggestion.pull(pin, resolve_pin_return_type(pin))
      @pin_suggestions[pin] ||= Suggestion.pull(pin)
    end

    def resolve_pin_return_type pin
      return pin.return_type unless pin.return_type.nil?
      return nil if pin.signature.nil?
      # Avoid infinite loops from variable assignments that reference themselves
      return nil if pin.name == pin.signature.split('.').first
      infer_signature_type(pin.signature, pin.namespace)
    end

  end
end
