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

    # Get a YardMap associated with the current workspace.
    #
    # @return [Solargraph::YardMap]
    def yard_map
      # refresh
      if @yard_map.nil? || @yard_map.required.to_set != required.to_set
        @yard_map = Solargraph::YardMap.new(required: required, workspace: workspace)
      end
      @yard_map
    end

    # Get a LiveMap associated with the current workspace.
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
      eliminate @virtual_source unless @virtual_source.nil?
      if workspace.has_source?(source)
        @sources = workspace.sources
        @virtual_source = nil
      else
        @virtual_source = source
        @sources = workspace.sources
        unless @virtual_source.nil?
          @sources.push @virtual_source
          process_virtual
        end
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
      return unless @force or changed?
      if force
        process_maps
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
        if @stime.nil? or source.stime > @stime
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
      return true if @stime.nil?
      return true if workspace.stime > @stime
      return true if !@virtual_source.nil? and @virtual_source.stime > @stime
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
      namespace ||= ''
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

    def find_fully_qualified_type namespace_type, context_type = ''
      namespace, scope = extract_namespace_and_scope(namespace_type)
      context = extract_namespace(context_type)
      fqns = find_fully_qualified_namespace(namespace, context)
      subtypes = get_subtypes(namespace_type)
      fqns = "#{fqns}<#{subtypes.join(', ')}>" unless subtypes.empty?
      return fqns if scope == :instance
      type = get_namespace_type(fqns)
      "#{type == :class ? 'Class<' : 'Module<'}#{fqns}>"
    end

    # Get a fully qualified namespace name. This method will start the search
    # in the specified root until it finds a match for the name.
    #
    # @param name [String] The namespace to match
    # @param root [String] The context to search
    # @return [String]
    def find_fully_qualified_namespace name, root = '', skip = []
      # refresh
      return nil if name.nil?
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
      suggest_unique_variables (@ivar_pins[namespace] || []).select{ |pin| pin.scope == scope }
    end

    # Get an array of class variable pins for a namespace.
    #
    # @param namespace [String] A fully qualified namespace
    # @return [Array<Solargraph::Pin::ClassVariable>]
    def get_class_variable_pins(namespace)
      suggest_unique_variables(@cvar_pins[namespace] || [])
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
      matches = []
      @sources.each do |source|
        matches.push source if source.include?(node)
      end
      matches.first
    end

    # @return [Array<Solargraph::Pin::GlobalVariable>]
    def get_global_variable_pins
      globals = []
      @sources.each do |s|
        globals.concat s.global_variable_pins
      end
      globals
    end

    def get_type_methods type, context = ''
      return [] if type.nil?
      namespace, scope = extract_namespace_and_scope(type)
      base = extract_namespace(context)
      fqns = find_fully_qualified_namespace(namespace, base)
      return [] if fqns.nil?
      visibility = [:public]
      visibility.push :private, :protected if fqns == base
      get_methods fqns, scope: scope, visibility: visibility
    end

    def get_methods fqns, scope: :instance, visibility: [:public], deep: true
      result = []
      if fqns == ''
        result.concat inner_get_methods(fqns, :class, visibility, deep, [])
        result.concat inner_get_methods(fqns, :instance, visibility, deep, [])
        result.concat inner_get_methods('Kernel', :instance, visibility, deep, [])
      else
        result.concat inner_get_methods(fqns, scope, visibility, deep, [])
      end
      # result.each{|pin| pin.resolve(self)}
      result
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
      return nil if signature.start_with?('.')
      # inner_infer_signature_type signature, namespace, scope, call_node, true
      base, rest = signature.split('.', 2)
      if base == 'self'
        if rest.nil?
          combine_type(namespace, scope)
        else
          inner_infer_signature_type(rest, namespace, scope, call_node, false)
        end
      else
        pins = infer_signature_pins(base, namespace, scope, call_node)
        return nil if pins.empty?
        pin = pins.first
        if rest.nil?
          pin.resolve self
          pin.return_type
        elsif pin.signature.nil? or pin.signature.empty?
          if pin.path.nil?
            pin.resolve self
            fqtype = find_fully_qualified_type(pin.return_type, namespace)
            return nil if fqtype.nil?
            subns, subsc = extract_namespace_and_scope(fqtype)
            inner_infer_signature_type(rest, subns, subsc, call_node, true)
          else
            inner_infer_signature_type(rest, pin.path, scope, call_node, true)
          end
        else
          subtype = inner_infer_signature_type(pin.signature, namespace, scope, call_node, true)
          subns, subsc = extract_namespace_and_scope(subtype)
          inner_infer_signature_type(rest, subns, subsc, call_node, false)
        end
      end
    end

    def complete fragment
      return [] if fragment.string? or fragment.comment?
      result = []
      if fragment.base.empty?
        if fragment.signature.start_with?('@@')
          result.concat get_class_variable_pins(fragment.namespace)
        elsif fragment.signature.start_with?('@')
          result.concat get_instance_variable_pins(fragment.namespace, fragment.scope)
        elsif fragment.signature.start_with?('$')
          result.concat get_global_variable_pins
        elsif fragment.signature.start_with?(':') and !fragment.signature.start_with?('::')
          result.concat get_symbols
        else
          unless fragment.signature.include?('::')
            result.concat fragment.local_variable_pins
            result.concat get_type_methods(fragment.namespace, fragment.namespace)
            result.concat ApiMap.keywords
          end
          result.concat get_constants(fragment.base, fragment.namespace)
        end
      else
        if fragment.signature.include?('::') and !fragment.signature.include?('.')
          result.concat get_constants(fragment.base, fragment.namespace)
        else
          type = infer_signature_type(fragment.base, fragment.namespace, scope: fragment.scope, call_node: fragment.node)
          result.concat get_type_methods(type)
        end
      end
      result.uniq(&:identifier).select{|s| s.kind != Solargraph::LanguageServer::CompletionItemKinds::METHOD or s.name.match(/^[a-z0-9_]*(\!|\?|=)?$/i)}.sort_by.with_index{ |x, idx| [x.name, idx] }
    end

    def define fragment
      return [] if fragment.string? or fragment.comment?
      pins = infer_signature_pins fragment.whole_signature, fragment.namespace, fragment.scope, fragment.node
      return [] if pins.empty?
      if pins.first.variable?
        result = []
        pins.select{|pin| pin.variable?}.each do |pin|
          pin.resolve self
          result.concat infer_signature_pins(pin.return_type, fragment.namespace, fragment.scope, fragment.node)
        end
        result
      else
        pins.reject{|pin| pin.path.nil?}
      end
    end

    # Identify the variable, constant, or method call at the fragment's location.
    #
    # @param fragment [Solargraph::Source::Fragment]
    # @return [Array<Solargraph::Pin::Base>]
    def identify fragment
      pins = infer_signature_pins(fragment.whole_signature, fragment.namespace, fragment.scope, fragment.node)
      pins.each { |pin| pin.resolve self }
      pins
    end

    def infer_signature_pins signature, namespace, scope, call_node
      return [] if signature.nil? or signature.empty?
      base, rest = signature.split('.', 2)
      if base.start_with?('@@')
        pin = get_class_variable_pins(namespace).select{|pin| pin.name == base}.first
        return [] if pin.nil?
        return [pin] if rest.nil?
        fqns = find_fully_qualified_namespace(pin.return_type, namespace)
        return [] if fqns.nil?
        return inner_infer_signature_pins rest, namespace, scope, call_node, false
      elsif base.start_with?('@')
        pin = get_instance_variable_pins(namespace, scope).select{|pin| pin.name == base}.first
        return [] if pin.nil?
        pin.resolve self
        return [pin] if rest.nil?
        fqtype = find_fully_qualified_type(pin.return_type, namespace)
        return [] if fqtype.nil?
        subns, subsc = extract_namespace_and_scope(fqtype)
        return inner_infer_signature_pins rest, subns, subsc, call_node, false
      elsif base.start_with?('$')
        # @todo globals
      else
        type = find_fully_qualified_namespace(base, namespace)
        unless type.nil?
          if rest.nil?
            return get_path_suggestions(type)
          else
            return inner_infer_signature_pins rest, type, :class, call_node, false
          end
        end
        source = get_source_for(call_node)
        unless source.nil?
          lvpins = source.local_variable_pins.select{|pin| pin.name == base and pin.visible_from?(call_node)}
          unless lvpins.empty?
            if rest.nil?
              return lvpins
            else
              lvp = lvpins.first
              lvp.resolve self
              type = lvp.return_type
              unless type.nil?
                fqtype = find_fully_qualified_type(type, namespace)
                return [] if fqtype.nil?
                subns, subsc = extract_namespace_and_scope(fqtype)
                return inner_infer_signature_pins(rest, subns, subsc, call_node, false)
              end
            end
          end
        end
        return inner_infer_signature_pins signature, namespace, scope, call_node, true
      end
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

    def combine_type namespace, scope
      if scope == :instance
        namespace
      else
        type = get_namespace_type(namespace)
        "#{type == :class ? 'Class' : 'Module'}<#{namespace}>"
      end
    end

    # Get an array of all suggestions that match the specified path.
    #
    # @param path [String] The path to find
    # @return [Array<Solargraph::Pin::Base>]
    def get_path_suggestions path
      return [] if path.nil?
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
      # @todo Resolve the pins?
      result.map{|pin| pin.resolve(self); pin}
      # result
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

    def superclass_of fqns
      @superclasses[fqns]
    end

    def locate_pin location
      @sources.each do |source|
        pin = source.locate_pin(location)
        unless pin.nil?
          pin.resolve self
          return pin
        end
      end
      nil
    end

    private

    # @return [Hash]
    def namespace_map
      @namespace_map ||= {}
    end

    def process_maps
      @sources = workspace.sources
      @sources.push @virtual_source unless @virtual_source.nil?
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
      end
      result
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

    # Extract a namespace from a type.
    #
    # @example
    #   extract_namespace('String') => 'String'
    #   extract_namespace('Class<String>') => 'String'
    #
    # @return [String]
    def extract_namespace type
      extract_namespace_and_scope(type)[0]
    end

    # Extract a namespace and a scope (:instance or :class) from a type.
    #
    # @example
    #   extract_namespace('String')            #=> ['String', :instance]
    #   extract_namespace('Class<String>')     #=> ['String', :class]
    #   extract_namespace('Module<Enumerable') #=> ['Enumberable', :class]
    #
    # @return [Array] The namespace (String) and scope (Symbol).
    def extract_namespace_and_scope type
      scope = :instance
      result = type.to_s.gsub(/<.*$/, '')
      if (result == 'Class' or result == 'Module') and type.include?('<')
        result = type.match(/<([a-z0-9:_]*)/i)[1]
        scope = :class
      end
      [result, scope]
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
      return get_call_arguments(node.children[1]) if [:ivasgn, :cvasgn, :lvasgn].include?(node.type)
      return [] unless node.type == :send
      result = []
      node.children[2..-1].each do |c|
        result.push unpack_name(c)
      end
      result
    end

    # @todo This method shouldn't need to calculate the path. In fact, it should work directly off a pin.
    def get_return_type_from_macro namespace, signature, call_node, scope, visibility
      return nil if signature.empty? or signature.include?('.') or call_node.nil?
      path = "#{namespace}#{scope == :class ? '.' : '#'}#{signature}"
      macmeth = get_path_suggestions(path).first
      type = nil
      unless macmeth.nil?
        macmeths = Suggestion.pull(macmeth)
        macro = path_macros[macmeth.path]
        macro = macro.first unless macro.nil?
        # @todo Smelly respond_to? call
        if macro.nil? and macmeth.respond_to?(:code_object) and !macmeth.code_object.nil? and !macmeth.code_object.base_docstring.nil? and macmeth.code_object.base_docstring.all.include?('@!macro')
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

    def inner_infer_signature_type signature, namespace, scope, call_node, top
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
      parts = signature.split('.', 2)
      type = find_fully_qualified_namespace(parts[0], namespace)
      if type.nil?
        # It's a variable or method call
        if top and parts[0] == 'self'
          if parts[1].nil?
            result = namespace
          else
            return inner_infer_signature_type(parts[1], namespace, scope, call_node, false)
          end
        elsif parts[0] == 'new' and scope == :class
          scope = :instance
          if parts[1].nil?
            result = namespace
          else
            result = inner_infer_signature_type(parts[1], namespace, :instance, call_node, false)
          end
        else
          visibility = [:public]
          visibility.concat [:private, :protected] if top
          if scope == :instance || namespace == ''
            tmp = get_methods(extract_namespace(namespace), visibility: visibility)
          else
            tmp = get_methods(namespace, visibility: visibility, scope: :class)
            # tmp = get_type_methods(namespace, (top ? namespace : ''))
          end
          tmp.concat get_methods('Kernel', visibility: [:public]) if top
          matches = tmp.select{|s| s.name == parts[0]}
          return nil if matches.empty?
          matches.each do |m|
            type = get_return_type_from_macro(namespace, signature, call_node, scope, visibility)
            if type.nil?
              if METHODS_RETURNING_SELF.include?(m.path)
                type = curtype
              elsif METHODS_RETURNING_SUBTYPES.include?(m.path)
                subtypes = get_subtypes(namespace)
                type = subtypes[0]
              elsif !m.return_type.nil?
                if m.return_type == 'self'
                  type = combine_type(namespace, scope)
                else
                  type = m.return_type
                end
              end
            end
            break unless type.nil?
          end
          unless type.nil?
            scope = :instance
            if parts[1].nil?
              result = type
            else
              subns, subsc = extract_namespace_and_scope(type)
              result = inner_infer_signature_type(parts[1], subns, subsc, call_node, false)
            end
          end
        end
      else
        return inner_infer_signature_type(parts[1], type, :class, call_node, false)
      end
      # @todo Assuming `self` only works at the top level
      # result = type if result == 'self'
      unless result.nil?
        if scope == :class
          nstype = get_namespace_type(result)
          result = "#{nstype == :class ? 'Class<' : 'Module<'}#{result}>"
        end
      end
      cache.set_signature_type signature, namespace, scope, result
      result
    end

    # @todo call_node might be superfluous here. We're already past looking for local variables.
    def inner_infer_signature_pins signature, namespace, scope, call_node, top
      base, rest = signature.split('.', 2)
      type = nil
      if rest.nil?
        visibility = [:public]
        visibility.push :private, :protected if top
        methods = []
        methods.concat get_methods(namespace, visibility: visibility, scope: scope).select{|pin| pin.name == base}
        methods.concat get_methods('Kernel', scope: :instance).select{|pin| pin.name == base} if top
        return methods
      else
        type = inner_infer_signature_type base, namespace, scope, call_node, top
        nxt_ns, nxt_scope = extract_namespace_and_scope(type)
        return inner_infer_signature_pins rest, nxt_ns, nxt_scope, call_node, false
      end
    end

    def current_workspace_sources
      @sources - [@virtual_source]
    end
  end
end
