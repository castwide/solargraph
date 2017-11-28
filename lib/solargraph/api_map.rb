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

    # @param workspace [String]
    def initialize workspace = nil
      @workspace = workspace.gsub(/\\/, '/') unless workspace.nil?
      clear
      require_extensions
      unless @workspace.nil?
        workspace_files.concat (self.config.included - self.config.excluded)
        workspace_files.each do |wf|
          begin
            @@source_cache[wf] ||= Source.load(wf)
          rescue Exception => e
            STDERR.puts "Failed to load #{wf}: #{e.message}"
          end
        end
      end
      @sources = {}
      @virtual_source = nil
      @virtual_filename = nil
      @stale = true
      refresh
      yard_map
    end

    # @return [Solargraph::ApiMap::Config]
    def config reload = false
      @config = ApiMap::Config.new(@workspace) if @config.nil? or reload
      @config
    end

    def workspace_files
      @workspace_files ||= []
    end

    # @return [Array<String>]
    def required
      @required ||= []
    end

    # @return [Solargraph::YardMap]
    def yard_map
      refresh
      if @yard_map.nil? || @yard_map.required != required
        @yard_map = Solargraph::YardMap.new(required: required, workspace: workspace)
      end
      @yard_map
    end

    # @return [Solargraph::LiveMap]
    def live_map
      @live_map ||= Solargraph::LiveMap.new(self)
    end

    # @todo Get rid of the cursor parameter. Tracking stubbed lines is the
    #   better option.
    #
    # @param code [String]
    # @param filename [String]
    # @return [Solargraph::ApiMap::Source]
    def virtualize code, filename = nil, cursor = nil
      workspace_files.delete_if do |f|
        if File.exist?(f)
          false
        else
          eliminate f
          true
        end
      end
      if filename.nil? or filename.end_with?('.rb')
        eliminate @virtual_filename unless @virtual_source.nil? or @virtual_filename == filename or workspace_files.include?(@virtual_filename)
        @virtual_filename = filename
        @virtual_source = Source.fix(code, filename, cursor)
        unless filename.nil? or workspace_files.include?(filename)
          current_files = @workspace_files
          @workspace_files = config(true).calculated
          (current_files - @workspace_files).each { |f| eliminate f }
        end
        process_virtual
      else
        unless filename.nil?
          # @todo Handle special files like .solargraph.yml
        end
      end
      @virtual_source
    end

    # @return [Solargraph::ApiMap::Source]
    def append_source code, filename
      virtualize code, filename
    end

    def refresh force = false
      process_maps if @stale or force
    end

    # Get the docstring associated with a node.
    #
    # @param node [AST::Node]
    # @return [YARD::Docstring]
    def get_docstring_for node
      filename = get_filename_for(node)
      return nil if @sources[filename].nil?
      @sources[filename].docstring_for(node)
    end

    # @deprecated
    def get_comment_for node
      get_docstring_for node
    end

    # @return [Array<Solargraph::Suggestion>]
    def self.get_keywords
      @keyword_suggestions ||= KEYWORDS.map{ |s|
        Suggestion.new(s.to_s, kind: Suggestion::KEYWORD, detail: 'Keyword')
      }.freeze
    end

    # @return [Array<String>]
    def namespaces
      refresh
      namespace_map.keys
    end

    def namespace_exists? name, root = ''
      !find_fully_qualified_namespace(name, root).nil?
    end

    # @deprecated
    def namespaces_in name, root = ''
      get_constants name, root
    end

    # @return [Array<Solargraph::Pin::Constant>]
    def get_constant_pins namespace, root
      fqns = find_fully_qualified_namespace(namespace, root)
      @const_pins[fqns] || []
    end

    # @return [Array<Solargraph::Suggestion>]
    def get_constants namespace, root = ''
      result = []
      skip = []
      fqns = find_fully_qualified_namespace(namespace, root)
      if fqns.empty?
        result.concat inner_get_constants('', skip, false)
      else fqns.empty?
        parts = fqns.split('::')
        while parts.length > 0
          resolved = find_namespace_pins(parts.join('::'))
          resolved.each do |pin|
            result.concat inner_get_constants(pin.path, skip, true)
          end
          parts.pop
        end
      end
      result.concat yard_map.get_constants(fqns)
      result
    end

    def find_namespace_pins fqns
      set = nil
      if fqns.include?('::')
        set = @namespace_pins[fqns.split('::')[0..-2]]
      else
        set = @namespace_pins['']
      end
      return [] if set.nil?
      set.select{|p| p.path == fqns}
    end

    # @return [String]
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
          return name unless namespace_map[name].nil?
          get_include_strings_from(*file_nodes).each { |i|
            reroot = "#{root == '' ? '' : root + '::'}#{i}"
            recname = find_fully_qualified_namespace name.to_s, reroot, skip
            return recname unless recname.nil?
          }
        else
          roots = root.to_s.split('::')
          while roots.length > 0
            fqns = roots.join('::') + '::' + name
            return fqns unless namespace_map[fqns].nil?
            roots.pop
          end
          return name unless namespace_map[name].nil?
          get_include_strings_from(*file_nodes).each { |i|
            recname = find_fully_qualified_namespace name, i, skip
            return recname unless recname.nil?
          }
        end
      end
      result = yard_map.find_fully_qualified_namespace(name, root)
      if result.nil?
        result = live_map.get_fqns(name, root)
      end
      result
    end

    def get_namespace_nodes(fqns)
      return file_nodes if fqns == '' or fqns.nil?
      refresh
      namespace_map[fqns] || []
    end

    # @return [Array<Solargraph::Pin::InstanceVariable>]
    def get_instance_variable_pins(namespace, scope = :instance)
      refresh
      (@ivar_pins[namespace] || []).select{ |pin| pin.scope == scope }
    end

    # @return [Array<Solargraph::Suggestion>]
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

    # @return [Array<Solargraph::Pin::ClassVariable>]
    def get_class_variable_pins(namespace)
      refresh
      @cvar_pins[namespace] || []
    end

    # @return [Array<Solargraph::Suggestion>]
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

    # @return [Array<Solargraph::Pin::Symbol>]
    def get_symbols
      refresh
      @symbol_pins.uniq(&:label)
    end

    # @return [String]
    def get_filename_for(node)
      @sources.each do |filename, source|
        return source.filename if source.include?(node)
      end
      nil
    end

    # @return [Solargraph::ApiMap::Source]
    def get_source_for(node)
      @sources.each do |filename, source|
        return source if source.include?(node)
      end
      nil
    end

    # @return [String]
    def infer_instance_variable(var, namespace, scope)
      refresh
      pins = @ivar_pins[namespace]
      return nil if pins.nil?
      pin = pins.select{|p| p.name == var and p.scope == scope}.first
      return nil if pin.nil?
      pin.return_type
    end

    # @return [String]
    def infer_class_variable(var, namespace)
      refresh
      fqns = find_fully_qualified_namespace(namespace)
      pins = @cvar_pins[fqns]
      return nil if pins.nil?
      pin = pins.select{|p| p.name == var}.first
      return nil if pin.nil?
      pin.return_type
    end

    # @return [Array<Solargraph::Suggestion>]
    def get_global_variables
      result = []
      @sources.values.each do |s|
        s.global_variable_pins.each do |p|
          result.push pin_to_suggestion(p)
        end
      end
      result
    end

    # @return [String]
    def infer_assignment_node_type node, namespace
      type = cache.get_assignment_node_type(node, namespace)
      if type.nil?
        cmnt = get_docstring_for(node)
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

    # @return [String]
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

    def get_namespace_type fqns
      return nil if fqns.nil?
      type = nil
      nodes = get_namespace_nodes(fqns)
      unless nodes.nil? or nodes.empty? or !nodes[0].kind_of?(AST::Node)
        type = nodes[0].type if [:class, :module].include?(nodes[0].type)
      end
      if type.nil?
        type = yard_map.get_namespace_type(fqns)
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
      fqns = find_fully_qualified_namespace(namespace, root)
      meths = []
      skip = []
      meths.concat inner_get_methods(namespace, root, skip)
      yard_meths = yard_map.get_methods(fqns, '', visibility: visibility)
      if yard_meths.any?
        meths.concat yard_meths
      else
        type = get_namespace_type(fqns)
        if type == :class
          meths.concat yard_map.get_instance_methods('Class')
        else
          meths.concat yard_map.get_methods('Module')
        end
      end
      news = meths.select{|s| s.label == 'new'}
      unless news.empty?
        if @method_pins[fqns]
          inits = @method_pins[fqns].select{|p| p.name == 'initialize'}
          meths -= news unless inits.empty?
          inits.each do |pin|
            meths.push Suggestion.new('new', kind: pin.kind, docstring: pin.docstring, detail: pin.namespace, arguments: pin.parameters, path: pin.path)
          end
        end
      end
      if namespace == '' and root == ''
        config.domains.each do |d|
          meths.concat get_instance_methods(d)
        end
      end
      strings = meths.map(&:to_s)
      live_map.get_methods(fqns, '', 'class', visibility.include?(:private)).each do |m|
        next if strings.include?(m) or !m.match(/^[a-z]/i)
        meths.push Suggestion.new(m, kind: Suggestion::METHOD, docstring: YARD::Docstring.new('(defined at runtime)'), path: "#{fqns}.#{m}")
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
        type = get_namespace_type(fqns)
        if type == :class
          meths += yard_map.get_instance_methods('Object')
        elsif type == :module
          meths += yard_map.get_instance_methods('Module')
        end
      end
      strings = meths.map(&:to_s)
      live_map.get_methods(namespace, root, 'instance', visibility.include?(:private)).each do |m|
        next if strings.include?(m) or !m.match(/^[a-z]/i)
        meths.push Suggestion.new(m, kind: Suggestion::METHOD, docstring: YARD::Docstring.new('(defined at runtime)'), path: "#{fqns}##{m}")
      end
      meths
    end

    # @return [Array<String>]
    def get_include_strings_from *nodes
      arr = []
      nodes.each { |node|
        next unless node.kind_of?(AST::Node)
        arr.push unpack_name(node.children[2]) if (node.type == :send and node.children[1] == :include)
        node.children.each { |n|
          arr += get_include_strings_from(n) if n.kind_of?(AST::Node) and n.type != :class and n.type != :module and n.type != :sclass
        }
      }
      arr
    end

    def update filename
      filename.gsub!(/\\/, '/')
      eliminate filename
      @@source_cache[filename] = Source.load(filename)
      rebuild_local_yardoc #if @workspace_files.include?(filename)
      @stale = true
    end

    def sources
      @sources.values
    end

    def get_path_suggestions path
      refresh
      result = []
      if path.include?('#')
        # It's an instance method
        parts = path.split('#')
        result = get_instance_methods(parts[0], '', visibility: [:public, :private, :protected]).select{|s| s.label == parts[1]}
      elsif path.include?('.')
        # It's a class method
        parts = path.split('.')
        result = get_methods(parts[0], '', visibility: [:public, :private, :protected]).select{|s| s.label == parts[1]}
      else
        # It's a class or module
        parts = path.split('::')
        np = @namespace_pins[parts[0..-2].join('::')]
        unless np.nil?
          result.concat np.select{|p| p.name == parts.last}.map{|p| pin_to_suggestion(p)}
        end
        result.concat yard_map.objects(path)
      end
      result
    end

    private

    # @return [Hash]
    def namespace_map
      @namespace_map ||= {}
    end

    def clear
      @stale = false
      namespace_map.clear
      required.clear
    end

    def process_maps
      process_workspace_files
      cache.clear
      @ivar_pins = {}
      @cvar_pins = {}
      @const_pins = {}
      @method_pins = {}
      @symbol_pins = []
      @attr_pins = {}
      @namespace_includes = {}
      @superclasses = {}
      @namespace_pins = {}
      namespace_map.clear
      @required = config.required.clone
      @pin_suggestions = {}
      unless @virtual_source.nil?
        @sources[@virtual_filename] = @virtual_source
      end
      @sources.values.each do |s|
        s.namespace_nodes.each_pair do |k, v|
          namespace_map[k] ||= []
          namespace_map[k].concat v
        end
      end
      @sources.values.each { |s|
        map_source s
      }
      @required.uniq!
      live_map.refresh
      @stale = false
    end

    def rebuild_local_yardoc
      return if workspace.nil? or !File.exist?(File.join(workspace, '.yardoc'))
      STDERR.puts "Rebuilding local yardoc for #{workspace}"
      Dir.chdir(workspace) { Process.spawn('yardoc') }
    end

    def process_workspace_files
      @sources.clear
      workspace_files.each do |f|
        if File.file?(f)
          begin
            @@source_cache[f] ||= Source.load(f)
            @sources[f] = @@source_cache[f]
          rescue Exception => e
            STDERR.puts "Failed to load #{f}: #{e.message}"
          end
        end
      end
    end

    def process_virtual
      unless @virtual_source.nil?
        cache.clear
        namespace_map.clear
        @sources[@virtual_filename] = @virtual_source
        @sources.values.each do |s|
          s.namespace_nodes.each_pair do |k, v|
            namespace_map[k] ||= []
            namespace_map[k].concat v
          end
        end
        eliminate @virtual_filename
        map_source @virtual_source
      end
    end

    def eliminate filename
      [@ivar_pins.values, @cvar_pins.values, @const_pins.values, @method_pins.values, @attr_pins.values, @namespace_pins.values].each do |pinsets|
        pinsets.each do |pins|
          pins.delete_if{|pin| pin.filename == filename}
        end
      end
      #@symbol_pins.delete_if{|pin| pin.filename == filename}
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
      source.namespace_pins.each do |pin|
        @namespace_pins[pin.namespace] ||= []
        @namespace_pins[pin.namespace].push pin
      end
      source.required.each do |r|
        required.push r
      end
    end

    # @return [Solargraph::ApiMap::Cache]
    def cache
      @cache ||= Cache.new
    end

    def inner_get_methods(namespace, root = '', skip = [], visibility = [:public])
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
      if visibility.include?(:public) or visibility.include?(:protected)
        sc = @superclasses[fqns]
        unless sc.nil?
          meths.concat inner_get_methods(sc, fqns, skip, visibility - [:private])
          meths.concat yard_map.get_methods(sc, fqns, visibility: visibility - [:private])
          strings = meths.map(&:to_s)
          live_map.get_methods(sc, fqns, 'class', false).each do |m|
            next if strings.include?(m) or !m.match(/^[a-z]/i)
            meths.push Suggestion.new(m, kind: Suggestion::METHOD, docstring: YARD::Docstring.new('(defined at runtime)'), path: "#{fqns}##{m}")
          end
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
          strings = meths.map(&:to_s)
          live_map.get_methods(sc, fqns, 'instance', false).each do |m|
            next if strings.include?(m) or !m.match(/^[a-z]/i)
            meths.push Suggestion.new(m, kind: Suggestion::METHOD, docstring: YARD::Docstring.new('(defined at runtime)'))
          end
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

    # Get a fully qualified namespace for the given signature.
    # The signature should be in the form of a method chain, e.g.,
    # method1.method2
    #
    # @return [String] The fully qualified namespace for the signature's type
    #   or nil if a type could not be determined
    def inner_infer_signature_type signature, namespace, scope: :instance, top: true
      return nil if signature.nil?
      signature.gsub!(/\.$/, '')
      if signature.empty?
        if scope == :class
          return "Class<#{namespace}>"
        else
          return "#{namespace}"
        end
      end
      parts = signature.split('.')
      type = namespace || ''
      while (parts.length > 0)
        part = parts.shift
        if top == true and part == 'self'
          top = false
          next
        end
        cls_match = type.match(/^Class<([A-Za-z0-9_:]*?)>$/)
        if cls_match
          type = cls_match[1]
          scope = :class
        end
        if scope == :class and part == 'new'
          scope = :instance
        elsif !METHODS_RETURNING_SELF.include?(part)
          visibility = [:public]
          visibility.concat [:private, :protected] if top
          if scope == :instance || namespace == ''
            tmp = get_instance_methods(namespace, visibility: visibility)
          else
            tmp = get_methods(namespace, visibility: visibility)
          end
          tmp.concat get_instance_methods('Kernel', visibility: [:public]) if top
          meth = tmp.select{|s| s.label == part}.first
          return nil if meth.nil? or meth.return_type.nil?
          type = meth.return_type
          scope = :instance
        end
        top = false
      end
      if scope == :class
        type = "Class<#{type}>"
      end
      type
    end

    def inner_get_constants here, skip = [], deep = true
      return [] if skip.include?(here)
      skip.push here
      result = []
      cp = @const_pins[here]
      unless cp.nil?
        cp.each do |pin|
          result.push pin_to_suggestion(pin)
        end
      end
      np = @namespace_pins[here]
      unless np.nil?
        np.each do |pin|
          result.push pin_to_suggestion(pin)
          if deep
            get_include_strings_from(pin.node).each do |i|
              result.concat inner_get_constants(i, skip, false)
            end
          end
        end
      end
      get_include_strings_from(*get_namespace_nodes(here)).each do |i|
        result.concat inner_get_constants(i, skip, false)
      end
      result
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

    # @param pin [Solargraph::Pin::Base]
    # @return [Solargraph::Suggestion]
    def pin_to_suggestion pin
      @pin_suggestions[pin] ||= Suggestion.pull(pin)
    end

    def require_extensions
      Gem::Specification.all_names.select{|n| n.match(/^solargraph\-[a-z0-9_\-]*?\-ext\-[0-9\.]*$/)}.each do |n|
        STDERR.puts "Loading extension #{n}"
        require n.match(/^(solargraph\-[a-z0-9_\-]*?\-ext)\-[0-9\.]*$/)[1]
      end
    end
  end
end
