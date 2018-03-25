require 'rubygems'
require 'thread'
require 'set'
require 'time'

module Solargraph
  class ApiMap
    autoload :Cache,        'solargraph/api_map/cache'
    autoload :SourceToYard, 'solargraph/api_map/source_to_yard'

    include NodeMethods
    include Solargraph::ApiMap::SourceToYard
    include CoreFills

    # The workspace to analyze and process.
    #
    # @return [Solargraph::Workspace]
    attr_reader :workspace

    # @param workspace [Solargraph::Workspace]
    def initialize workspace = nil
      # @todo Deprecate strings for the workspace parameter
      workspace = Solargraph::Workspace.new(workspace) if workspace.kind_of?(String)
      workspace = Solargraph::Workspace.new(nil) if workspace.nil?
      @workspace = workspace
      require_extensions
      @virtual_source = nil
      @yard_stale = true
      @sources = @workspace.sources
      process_maps
      yard_map
    end

    def self.load directory
      self.new(Solargraph::Workspace.new(directory))
    end

    # An array of required paths in the workspace.
    #
    # @return [Array<String>]
    def required
      @required ||= []
    end

    # Get a YardMap associated with the current namespace.
    #
    # @return [Solargraph::YardMap]
    def yard_map
      # refresh
      if @yard_map.nil? || @yard_map.required.to_set != required.to_set
        @yard_map = Solargraph::YardMap.new(required: required, workspace: workspace)
      end
      @yard_map
    end

    # Get a LiveMap associated with the current namespace.
    #
    # @return [Solargraph::LiveMap]
    def live_map
      @live_map ||= Solargraph::LiveMap.new(self)
    end

    # Declare a virtual source that will be included in the map regardless of
    # whether it's in the workspace.
    #
    # If the source is in the workspace, virtualizing it has no effect. Only
    # one source can be virtualized at a time.
    #
    # @param [Solargraph::Source]
    def virtualize source
      # return if @virtual_source == source
      # eliminate @virtual_source unless @virtual_source.nil?
      eliminate @virtual_source unless @virtual_source.nil?
      if workspace.has_source?(source)
        @sources = workspace.sources
        @virtual_source = nil
      else
        @virtual_source = source
        @sources = workspace.sources + [@virtual_source]
        process_virtual
        # process_maps
      end
    end

    # @todo Candidate for deprecation
    def append_source code, filename = nil
      source = Source.load_string(code, filename)
      virtualize source
    end

    # Refresh the ApiMap.
    #
    # @param force [Boolean] Perform a refresh even if the map is not "stale."
    def refresh force = false
      if !@stime.nil? and !workspace.stime.nil? and workspace.stime < @stime and workspace.sources.length == current_workspace_sources.length
        return
      end
      current_workspace_sources.reject{|s| workspace.sources.include?(s)}.each do |source|
        eliminate source
      end
      @sources = workspace.sources
      @sources.push @virtual_source unless @virtual_source.nil?
      cache.clear
      namespace_map.clear
      @sources.each do |s|
        s.namespace_nodes.each_pair do |k, v|
          namespace_map[k] ||= []
          namespace_map[k].concat v
        end
      end
      @sources.each do |source|
        if source.stime > @stime
          eliminate source
          map_source source
        end
      end
      @stime = Time.new
    end

    # True if a workspace file has been created, modified, or deleted since
    # the last time the map was processed.
    #
    # @return [Boolean]
    def changed?
      return true if current_workspace_sources.length != workspace.sources.length
      # @todo This needs to be refactored
      current = workspace.config.calculated
      unless (Set.new(current) ^ workspace.filenames).empty?
        return true
      end
      current.each do |f|
        if !File.exist?(f) or File.mtime(f) != source_file_mtime(f)
          return true
        end
      end
      false
    end

    # Get the docstring associated with a node.
    #
    # @param node [AST::Node]
    # @return [YARD::Docstring]
    def get_docstring_for node
      source = get_source_for(node)
      return nil if source.nil?
      source.docstring_for(node)
    end

    # An array of suggestions based on Ruby keywords (`if`, `end`, etc.).
    #
    # @return [Array<Solargraph::Pin::Keyword>]
    def self.keywords
      @keyword_suggestions ||= KEYWORDS.map{ |s|
        Pin::Keyword.new(s)
      }.freeze
    end

    # An array of namespace names defined in the ApiMap.
    #
    # @return [Array<String>]
    def namespaces
      # refresh
      namespace_map.keys
    end

    # True if the namespace exists.
    #
    # @param name [String] The namespace to match
    # @param root [String] The context to search
    # @return [Boolean]
    def namespace_exists? name, root = ''
      !find_fully_qualified_namespace(name, root).nil?
    end

    # Get an array of constant pins defined in the ApiMap. (This method does
    # not include constants from external gems or the Ruby core.)
    #
    # @param namespace [String] The namespace to match
    # @param root [String] The context to search
    # @return [Array<Solargraph::Pin::Constant>]
    def get_constant_pins namespace, root
      fqns = find_fully_qualified_namespace(namespace, root)
      @const_pins[fqns] || []
    end

    # Get suggestions for constants in the specified namespace. The result
    # will include constant variables, classes, and modules.
    #
    # @param namespace [String] The namespace to match
    # @param context [String] The context to search
    # @return [Array<Solargraph::Pin::Base>]
    def get_constants namespace, context = ''
      skip = []
      result = []
      if context.empty?
        visi = [:public]
        visi.push :private if namespace.empty?
        result.concat inner_get_constants(namespace, visi, skip)
      else
        parts = context.split('::')
        until parts.empty?
          subcontext = parts.join('::')
          fqns = find_fully_qualified_namespace(namespace, subcontext)
          visi = [:public]
          visi.push :private if namespace.empty? and subcontext == context
          result.concat inner_get_constants(fqns, visi, skip)
          parts.pop
        end
      end
      # result.map{|pin| Suggestion.pull(pin)}
      result
    end

    # Get a fully qualified namespace name. This method will start the search
    # in the specified root until it finds a match for the name.
    #
    # @param name [String] The namespace to match
    # @param root [String] The context to search
    # @return [String]
    def find_fully_qualified_namespace name, root = '', skip = []
      # refresh
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
          im = @namespace_includes['']
          unless im.nil?
            im.each do |i|
              reroot = "#{root == '' ? '' : root + '::'}#{i}"
              recname = find_fully_qualified_namespace name.to_s, reroot, skip
              return recname unless recname.nil?
            end
          end
        else
          roots = root.to_s.split('::')
          while roots.length > 0
            fqns = roots.join('::') + '::' + name
            return fqns unless namespace_map[fqns].nil?
            roots.pop
          end
          return name unless namespace_map[name].nil?
          im = @namespace_includes['']
          unless im.nil?
            im.each do |i|
              recname = find_fully_qualified_namespace name, i, skip
              return recname unless recname.nil?
            end
          end
        end
      end
      result = yard_map.find_fully_qualified_namespace(name, root)
      if result.nil?
        result = live_map.get_fqns(name, root)
      end
      result
    end

    # Get an array of instance variable pins defined in specified namespace
    # and scope.
    #
    # @param namespace [String] A fully qualified namespace
    # @param scope [Symbol] :instance or :class
    # @return [Array<Solargraph::Pin::InstanceVariable>]
    def get_instance_variable_pins(namespace, scope = :instance)
      # refresh
      (@ivar_pins[namespace] || []).select{ |pin| pin.scope == scope }
    end

    # Get an array of instance variable suggestions defined in specified
    # namespace and scope.
    #
    # @param namespace [String] A fully qualified namespace
    # @param scope [Symbol] :instance or :class
    # @return [Array<Solargraph::Pin::Base>]
    def get_instance_variables(namespace, scope = :instance)
      # refresh
      result = []
      ip = @ivar_pins[namespace]
      unless ip.nil?
        result.concat suggest_unique_variables(ip.select{ |pin| pin.scope == scope })
      end
      result
    end

    # @return [Array<Solargraph::Pin::ClassVariable>]
    def get_class_variable_pins(namespace)
      # refresh
      @cvar_pins[namespace] || []
    end

    # @return [Array<Solargraph::Pin::Base>]
    def get_class_variables(namespace)
      # refresh
      result = []
      cp = @cvar_pins[namespace]
      unless cp.nil?
        result.concat suggest_unique_variables(cp)
      end
      result
    end

    # @return [Array<Solargraph::Pin::Base>]
    def get_symbols
      # refresh
      @symbol_pins
    end

    # @return [String]
    def get_filename_for(node)
      @sources.each do |source|
        return source.filename if source.include?(node)
      end
      nil
    end

    # @return [Solargraph::Source]
    def get_source_for(node)
      @sources.each do |source|
        return source if source.include?(node)
      end
      nil
    end

    # @return [String]
    def infer_instance_variable(var, namespace, scope)
      # refresh
      pins = @ivar_pins[namespace]
      return nil if pins.nil?
      pin = pins.select{|p| p.name == var and p.scope == scope}.first
      return nil if pin.nil?
      type = nil
      type = find_fully_qualified_namespace(pin.return_type, pin.namespace) unless pin.return_type.nil?
      if type.nil?
        zparts = resolve_node_signature(pin.assignment_node).split('.')
        ztype = infer_signature_type(zparts[0..-2].join('.'), namespace, scope: :instance, call_node: pin.assignment_node)
        type = get_return_type_from_macro(ztype, zparts[-1], pin.assignment_node, :instance, [:public, :private, :protected])
      end
      type
    end

    # @return [String]
    def infer_class_variable(var, namespace)
      # refresh
      fqns = find_fully_qualified_namespace(namespace)
      pins = @cvar_pins[fqns]
      return nil if pins.nil?
      pin = pins.select{|p| p.name == var}.first
      return nil if pin.nil? or pin.return_type.nil?
      find_fully_qualified_namespace(pin.return_type, pin.namespace)
    end

    # @return [Array<Solargraph::Pin::Base>]
    def get_global_variables
      globals = []
      @sources.each do |s|
        globals.concat s.global_variable_pins
      end
      suggest_unique_variables globals
    end

    # @return [Array<Solargraph::Pin::GlobalVariable>]
    def get_global_variable_pins
      globals = []
      @sources.each do |s|
        globals.concat s.global_variable_pins
      end
      globals
    end

    # @return [String]
    def infer_assignment_node_type node, namespace
      cached = cache.get_assignment_node_type(node, namespace)
      return cached unless cached.nil?
      name_i = (node.type == :casgn ? 1 : 0)
      sig_i = (node.type == :casgn ? 2 : 1)
      type = infer_literal_node_type(node.children[sig_i])
      if type.nil?
        sig = resolve_node_signature(node.children[sig_i])
        # Avoid infinite loops from variable assignments that reference themselves
        return nil if node.children[name_i].to_s == sig.split('.').first
        type = infer_signature_type(sig, namespace, call_node: node.children[sig_i])
      end
      cache.set_assignment_node_type(node, namespace, type)
      type
    end

    def get_type_methods type, context = ''
      namespace_parts = clean_namespace_string(type).split('#')
      context_parts = clean_namespace_string(context).split('#')
      scope = (namespace_parts[1] ? :class : :instance)
      fqns = find_fully_qualified_namespace(namespace_parts[0], context_parts[0])
      return [] if fqns.nil?
      visibility = [:public]
      visibility.push :private, :protected if fqns == context_parts[0]
      get_methods fqns, scope: scope, visibility: visibility
    end

    def get_methods fqns, scope: :instance, visibility: [:public], deep: true
      result = []
      if fqns == ''
        result.concat inner_get_methods(fqns, :class, visibility, deep, [])
        result.concat inner_get_methods(fqns, :instance, visibility, deep, [])
      else
        result.concat inner_get_methods(fqns, scope, visibility, deep, [])
      end
      result.map{|pin| enhance pin}
    end

    # @deprecated
    # def get_instance_methods fqns, ignored = '', visibility: [:public], deep: true
    #   get_methods fqns, visibility: visibility
    # end

    def infer_fragment_type fragment
      infer_signature_type fragment.signature, fragment.namespace, call_node: fragment.node
    end

    # Get the return type for a signature within the specified namespace and
    # scope.
    #
    # @example
    #   api_map.infer_signature_type('String.new', '') #=> 'String'
    #
    # @param signature [String]
    # @param namespace [String] A fully qualified namespace
    # @param scope [Symbol] :class or :instance
    # @return [String]
    def infer_signature_type signature, namespace, scope: :class, call_node: nil
      namespace ||= ''
      if cache.has_signature_type?(signature, namespace, scope)
        return cache.get_signature_type(signature, namespace, scope)
      end
      return nil if signature.nil?
      return namespace if signature.empty? and scope == :instance
      return nil if signature.empty? # @todo This might need to return Class<namespace>
      if !signature.include?('.')
        fqns = find_fully_qualified_namespace(signature, namespace)
        unless fqns.nil? or fqns.empty?
          type = (get_namespace_type(fqns) == :class ? 'Class' : 'Module')
          return "#{type}<#{fqns}>"
        end
      end
      result = nil
      if namespace.end_with?('#class')
        result = infer_signature_type signature, namespace[0..-7], scope: (scope == :class ? :instance : :class), call_node: call_node
      else
        parts = signature.split('.', 2)
        if parts[0].start_with?('@@')
          type = infer_class_variable(parts[0], namespace)
          if type.nil? or parts.empty?
            result = inner_infer_signature_type(parts[1], type, scope: :instance, call_node: call_node)
          else
            result = type
          end
        elsif parts[0].start_with?('@')
          type = infer_instance_variable(parts[0], namespace, scope)
          if type.nil? or parts.empty?
            result = inner_infer_signature_type(parts[1], type, scope: :instance, call_node: call_node)
          else
            result = type
          end
        else
          type = find_fully_qualified_namespace(parts[0], namespace)
          if type.nil?
            # It's a method call
            type = inner_infer_signature_type(parts[0], namespace, scope: scope, call_node: call_node)
            if parts.length < 2
              if type.nil? and !parts.length.nil?
                path = "#{clean_namespace_string(namespace)}#{scope == :class ? '.' : '#'}#{parts[0]}"
                subtypes = get_subtypes(namespace)
                type = subtypes[0] if METHODS_RETURNING_SUBTYPES.include?(path)
              end
              result = type
            else
              result = inner_infer_signature_type(parts[1], type, scope: :instance, call_node: call_node)
            end
          else
            result = inner_infer_signature_type(parts[1], type, scope: :class, call_node: call_node)
          end
          result = type if result == 'self'
        end
      end
      cache.set_signature_type signature, namespace, scope, result
      result
    end

    # Get the namespace's type (Class or Module).
    #
    # @param [String] A fully qualified namespace
    # @return [Symbol] :class, :module, or nil
    def get_namespace_type fqns
      pin = @namespace_path_pins[fqns]
      return yard_map.get_namespace_type(fqns) if pin.nil?
      pin.first.type
    end

    # Get an array of all suggestions that match the specified path.
    #
    # @param path [String] The path to find
    # @return [Array<Solargraph::Pin::Base>]
    def get_path_suggestions path
      # refresh
      result = []
      if path.include?('#')
        # It's an instance method
        parts = path.split('#')
        result = get_methods(parts[0], visibility: [:public, :private, :protected]).select{|s| s.name == parts[1]}
      elsif path.include?('.')
        # It's a class method
        parts = path.split('.')
        result = get_methods(parts[0], scope: :class, visibility: [:public, :private, :protected]).select{|s| s.name == parts[1]}
      else
        # It's a class or module
        parts = path.split('::')
        np = @namespace_pins[parts[0..-2].join('::')]
        unless np.nil?
          result.concat np.select{|p| p.name == parts.last}
        end
        result.concat yard_map.objects(path)
      end
      result.map{|pin| enhance pin}
    end

    # Get a list of documented paths that match the query.
    #
    # @example
    #   api_map.query('str') # Results will include `String` and `Struct`
    #
    # @param query [String] The text to match
    # @return [Array<String>]
    def search query
      # refresh
      rake_yard(@sources) if @yard_stale
      @yard_stale = false
      found = []
      code_object_paths.each do |k|
        if found.empty? or (query.include?('.') or query.include?('#')) or !(k.include?('.') or k.include?('#'))
          found.push k if k.downcase.include?(query.downcase)
        end
      end
      found.concat(yard_map.search(query)).uniq.sort
    end

    # Get YARD documentation for the specified path.
    #
    # @example
    #   api_map.document('String#split')
    #
    # @param path [String] The path to find
    # @return [Array<YARD::CodeObject::Base>]
    def document path
      # refresh
      rake_yard(@sources) if @yard_stale
      @yard_stale = false
      docs = []
      docs.push code_object_at(path) unless code_object_at(path).nil?
      docs.concat yard_map.document(path)
      docs
    end

    def query_symbols query
      result = []
      @sources.each do |s|
        result.concat s.query_symbols(query)
      end
      result
    end

    private

    # @return [Hash]
    def namespace_map
      @namespace_map ||= {}
    end

    def process_maps
      cache.clear
      @ivar_pins = {}
      @cvar_pins = {}
      @const_pins = {}
      @method_pins = {}
      @symbol_pins = []
      @attr_pins = {}
      @namespace_includes = {}
      @namespace_extends = {}
      @superclasses = {}
      @namespace_pins = {}
      @namespace_path_pins = {}
      namespace_map.clear
      @required = workspace.config.required.clone
      @pin_suggestions = {}
      @sources.each do |s|
        s.namespace_nodes.each_pair do |k, v|
          namespace_map[k] ||= []
          namespace_map[k].concat v
        end
      end
      @sources.each do |s|
        map_source s
      end
      @required.uniq!
      live_map.refresh
      @yard_stale = true
      @stime = Time.now
    end

    def rebuild_local_yardoc
      return if workspace.nil? or !File.exist?(File.join(workspace, '.yardoc'))
      STDERR.puts "Rebuilding local yardoc for #{workspace}"
      Dir.chdir(workspace) { Process.spawn('yardoc') }
    end

    def process_virtual
      unless @virtual_source.nil?
        cache.clear
        namespace_map.clear
        @sources.each do |s|
          s.namespace_nodes.each_pair do |k, v|
            namespace_map[k] ||= []
            namespace_map[k].concat v
          end
        end
        map_source @virtual_source
      end
    end

    def eliminate source
      [@ivar_pins.values, @cvar_pins.values, @const_pins.values, @method_pins.values, @attr_pins.values, @namespace_pins.values].each do |pinsets|
        pinsets.each do |pins|
          pins.delete_if{|pin| pin.filename == source.filename}
        end
      end
      @symbol_pins.delete_if{|pin| pin.filename == source.filename}
    end

    # @param [Solargraph::Source]
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
        @symbol_pins.push pin
      end
      source.namespace_includes.each_pair do |ns, i|
        @namespace_includes[ns || ''] ||= []
        @namespace_includes[ns || ''].concat(i).uniq!
      end
      source.namespace_extends.each_pair do |ns, e|
        @namespace_extends[ns || ''] ||= []
        @namespace_extends[ns || ''].concat(e).uniq!
      end
      source.superclasses.each_pair do |cls, sup|
        @superclasses[cls] = sup
      end
      source.namespace_pins.each do |pin|
        @namespace_path_pins[pin.path] ||= []
        @namespace_path_pins[pin.path].push pin
        @namespace_pins[pin.namespace] ||= []
        @namespace_pins[pin.namespace].push pin
      end
      path_macros.merge! source.path_macros
      source.required.each do |r|
        required.push r
      end
    end

    # @return [Solargraph::ApiMap::Cache]
    def cache
      @cache ||= Cache.new
    end

    def inner_get_methods fqns, scope, visibility, deep, skip
      return [] if skip.include?(fqns)
      skip.push fqns
      result = []
      if scope == :instance
        aps = @attr_pins[fqns]
        result.concat aps unless aps.nil?
      end
      mps = @method_pins[fqns]
      result.concat mps.select{|pin| (pin.scope == scope or fqns == '') and visibility.include?(pin.visibility)} unless mps.nil?
      if deep
        sc = @superclasses[fqns]
        unless sc.nil?
          sc_visi = [:public]
          sc_visi.push :protected if visibility.include?(:protected)
          sc_fqns = find_fully_qualified_namespace(sc, fqns)
          result.concat inner_get_methods(sc_fqns, scope, sc_visi, true, skip)
        end
        if scope == :instance
          im = @namespace_includes[fqns]
          unless im.nil?
            im.each do |i|
              ifqns = find_fully_qualified_namespace(i, fqns)
              result.concat inner_get_methods(ifqns, scope, visibility, deep, skip)
            end
          end
          result.concat yard_map.get_instance_methods(fqns, visibility: visibility)
          result.concat inner_get_methods('Object', :instance, [:public], deep, skip) unless fqns == 'Object'
        else
          em = @namespace_extends[fqns]
          unless em.nil?
            em.each do |e|
              efqns = find_fully_qualified_namespace(e, fqns)
              result.concat inner_get_methods(efqns, :instance, visibility, deep, skip)
            end
          end
          type = get_namespace_type(fqns)
          result.concat yard_map.get_methods(fqns, '', visibility: visibility)
          if type == :class
            result.concat inner_get_methods('Class', :instance, [:public], deep, skip)
          else
            result.concat inner_get_methods('Module', :instance, [:public], deep, skip)
          end
        end
        # result.concat inner_get_methods_refactored('', :instance, [:public], deep, skip)
        # result.concat inner_get_methods_refactored('Object', :instance, [:public], deep, skip)
      end
      result
    end

    # Get a fully qualified namespace for the given signature.
    # The signature should be in the form of a method chain, e.g.,
    # method1.method2
    #
    # @return [String] The fully qualified namespace for the signature's type
    #   or nil if a type could not be determined
    def inner_infer_signature_type signature, namespace, scope: :instance, top: true, call_node: nil
      return nil if signature.nil?
      signature.gsub!(/\.$/, '')
      if signature.empty?
        if scope == :class
          type = get_namespace_type(namespace)
          if type == :class
            return "Class<#{namespace}>"
          else
            return "Module<#{namespace}>"
          end
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
        else
          curtype = type
          type = nil
          visibility = [:public]
          visibility.concat [:private, :protected] if top
          if scope == :instance || namespace == ''
            tmp = get_methods(clean_namespace_string(namespace), visibility: visibility)
          else
            tmp = get_methods(namespace, visibility: visibility, scope: :class)
            # tmp = get_type_methods(namespace, (top ? namespace : ''))
          end
          tmp.concat get_methods('Kernel', visibility: [:public]) if top
          matches = tmp.select{|s| s.name == part}
          return nil if matches.empty?
          matches.each do |m|
            type = get_return_type_from_macro(namespace, signature, call_node, scope, visibility)
            if type.nil?
              if METHODS_RETURNING_SELF.include?(m.path)
                type = curtype
              elsif METHODS_RETURNING_SUBTYPES.include?(m.path)
                subtypes = get_subtypes(namespace)
                type = subtypes[0]
              else
                type = m.return_type
              end
            end
            break unless type.nil?
          end
          scope = :instance
        end
        top = false
      end
      if scope == :class and !type.nil?
        type = "Class<#{type}>"
      end
      type
    end

    def inner_get_constants fqns, visibility, skip
      return [] if skip.include?(fqns)
      skip.push fqns
      result = []
      result.concat @const_pins[fqns] if @const_pins.has_key?(fqns)
      result.concat @namespace_pins[fqns] if @namespace_pins.has_key?(fqns)
      result.keep_if{|pin| visibility.include?(pin.visibility)}
      result.concat yard_map.get_constants(fqns)
      is = @namespace_includes[fqns]
      unless is.nil?
        is.each do |i|
          here = find_fully_qualified_namespace(i, fqns)
          result.concat inner_get_constants(here, [:public], skip)
        end
      end
      result
    end

    # @param namespace [String]
    # @return [String]
    def clean_namespace_string namespace
      result = namespace.to_s.gsub(/<.*$/, '')
      if result == 'Class' and namespace.include?('<')
        subtype = namespace.match(/<([a-z0-9:_]*)/i)[1]
        result = "#{subtype}#class"
      elsif result == 'Module' and namespace.include?('<')
        subtype = namespace.match(/<([a-z0-9:_]*)/i)[1]
        result = "#{subtype}#module"
      end
      result
    end

    def enhance pin
      return_type = nil
      return_type = find_fully_qualified_namespace(pin.return_type, pin.namespace) unless pin.return_type.nil?
      if return_type.nil? and pin.is_a?(Solargraph::Pin::Method)
        sc = @superclasses[pin.namespace]
        while return_type.nil? and !sc.nil?
          sc_path = "#{sc}#{pin.scope == :instance ? '#' : '.'}#{pin.name}"
          sugg = get_path_suggestions(sc_path).first
          break if sugg.nil?
          return_type = find_fully_qualified_namespace(sugg.return_type, sugg.namespace) unless sugg.return_type.nil?
          sc = @superclasses[sc]
        end
      end
      pin.instance_variable_set(:@return_type, return_type) unless return_type.nil?
      pin
    end

    def require_extensions
      Gem::Specification.all_names.select{|n| n.match(/^solargraph\-[a-z0-9_\-]*?\-ext\-[0-9\.]*$/)}.each do |n|
        STDERR.puts "Loading extension #{n}"
        require n.match(/^(solargraph\-[a-z0-9_\-]*?\-ext)\-[0-9\.]*$/)[1]
      end
    end

    # @return [Array<Solargraph::Pin::Base>]
    def suggest_unique_variables pins
      result = []
      nil_pins = []
      val_names = []
      pins.each do |pin|
        if pin.nil_assignment? and pin.return_type.nil?
          nil_pins.push pin
        else
          unless val_names.include?(pin.name)
            result.push pin
            val_names.push pin.name
          end
        end
      end
      nil_pins.reject{|p| val_names.include?(p.name)}.each do |pin|
        result.push pin
      end
      result
    end

    def source_file_mtime(filename)
      # @todo This is naively inefficient.
      @sources.each do |s|
        return s.mtime if s.filename == filename
      end
      nil
    end

    # @return [Array<Solargraph::Pin::Namespace>]
    def find_namespace_pins fqns
      set = nil
      if fqns.include?('::')
        set = @namespace_pins[fqns.split('::')[0..-2].join('::')]
      else
        set = @namespace_pins['']
      end
      return [] if set.nil?
      set.select{|p| p.path == fqns}
    end

    # @todo DRY this method. It's duplicated in CodeMap
    def get_subtypes type
      return nil if type.nil?
      match = type.match(/<([a-z0-9_:, ]*)>/i)
      return [] if match.nil?
      match[1].split(',').map(&:strip)
    end

    # @return [Hash]
    def path_macros
      @path_macros ||= {}
    end

    def get_call_arguments node
      return [] unless node.type == :send
      result = []
      node.children[2..-1].each do |c|
        result.push unpack_name(c)
      end
      result
    end

    def get_return_type_from_macro namespace, signature, call_node, scope, visibility
      return nil if signature.empty? or signature.include?('.') or call_node.nil?
      cleaned_parts = clean_namespace_string(namespace).split('#')
      scope = :class if cleaned_parts[1]
      path = "#{cleaned_parts[0]}#{scope == :class ? '.' : '#'}#{signature}"
      macmeth = get_path_suggestions(path).first
      type = nil
      unless macmeth.nil?
        macmeths = Suggestion.pull(macmeth)
        macro = path_macros[macmeth.path]
        macro = macro.first unless macro.nil?
        if macro.nil? and !macmeth.code_object.nil? and !macmeth.code_object.base_docstring.nil? and macmeth.code_object.base_docstring.all.include?('@!macro')
          all = YARD::Docstring.parser.parse(macmeth.code_object.base_docstring.all).directives
          macro = all.select{|m| m.tag.tag_name == 'macro'}.first
        end
        unless macro.nil?
          docstring = YARD::Docstring.parser.parse(macro.tag.text).to_docstring
          rt = docstring.tag(:return)
          unless rt.nil? or rt.types.nil? or call_node.nil?
            args = get_call_arguments(call_node)
            type = "#{args[rt.types[0][1..-1].to_i-1]}"
          end
        end
      end
      type
    end

    def current_workspace_sources
      @sources - [@virtual_source]
    end
  end
end
