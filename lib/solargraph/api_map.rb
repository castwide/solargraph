require 'rubygems'
require 'set'
require 'time'

module Solargraph
  # An aggregate provider for information about workspaces, sources, gems, and
  # the Ruby core.
  #
  class ApiMap
    autoload :Cache,        'solargraph/api_map/cache'
    autoload :SourceToYard, 'solargraph/api_map/source_to_yard'
    autoload :Store,        'solargraph/api_map/store'

    include Solargraph::ApiMap::SourceToYard
    include CoreFills

    # The workspace to analyze and process.
    #
    # @return [Solargraph::Workspace]
    attr_reader :workspace

    # Get a LiveMap associated with the current workspace.
    #
    # @return [Solargraph::LiveMap]
    attr_reader :live_map

    # @param workspace [Solargraph::Workspace]
    def initialize workspace = Solargraph::Workspace.new(nil)
      @workspace = workspace
      require_extensions
      @virtual_source = nil
      @sources = workspace.sources
      refresh_store_and_maps
    end

    # Create an ApiMap with a workspace in the specified directory.
    #
    # @param directory [String]
    # @return [ApiMap]
    def self.load directory
      self.new(Solargraph::Workspace.new(directory))
    end

    # @return [Array<Solargraph::Pin::Base>]
    def pins
      store.pins
    end

    # @return [Array<String>]
    def domains
      @domains ||= []
    end

    # An array of required paths in the workspace.
    #
    # @return [Array<String>]
    def required
      result = []
      @sources.each do |s|
        result.concat s.required.map(&:name)
      end
      result.concat workspace.config.required
      result.uniq
    end

    # Declare a virtual source that will be included in the map regardless of
    # whether it's in the workspace.
    #
    # If the source is in the workspace, virtualizing it has no effect. Only
    # one source can be virtualized at a time.
    #
    # @param source [Solargraph::Source]
    # @return [Solargraph::Source]
    def virtualize source
      # @todo Confirm the correct way to handle caches
      cache.clear if (source.nil? and !@virtual_source.nil?) or (!source.nil? and !@virtual_source.nil? and source.pins != @virtual_source.pins)
      store.remove @virtual_source unless @virtual_source.nil?
      domains.clear
      domains.concat workspace.config.domains
      domains.concat source.domains unless source.nil?
      domains.uniq!
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
      source
    end

    # Create a Source from the code and filename, and virtualize the result.
    # This method can be useful for directly testing the ApiMap. In practice,
    # applications should use a Library to synchronize the ApiMap to a
    # workspace.
    #
    # @param code [String]
    # @param filename [String]
    # @return [Solargraph::Source]
    def virtualize_string code, filename = nil
      source = Source.load_string(code, filename)
      virtualize source
    end

    # Refresh the ApiMap. This method checks for pending changes before
    # performing the refresh unless the `force` parameter is true.
    #
    # @param force [Boolean] Perform a refresh even if the map is not "stale."
    # @return [Boolean] True if a refresh was performed.
    def refresh force = false
      return false unless force or changed?
      if force
        refresh_store_and_maps
      else
        update_store_and_maps
      end
      true
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

    # An array of suggestions based on Ruby keywords (`if`, `end`, etc.).
    #
    # @return [Array<Solargraph::Pin::Keyword>]
    def self.keywords
      @keywords ||= KEYWORDS.map{ |s|
        Pin::Keyword.new(s)
      }.freeze
    end

    # An array of namespace names defined in the ApiMap.
    #
    # @return [Array<String>]
    def namespaces
      store.namespaces
    end

    # True if the namespace exists.
    #
    # @param name [String] The namespace to match
    # @param context [String] The context to search
    # @return [Boolean]
    def namespace_exists? name, context = ''
      !qualify(name, context).nil?
    end

    # Get suggestions for constants in the specified namespace. The result
    # may contain both constant and namespace pins.
    #
    # @param namespace [String] The namespace
    # @param context [String] The context
    # @return [Array<Solargraph::Pin::Base>]
    def get_constants namespace, context = ''
      namespace ||= ''
      cached = cache.get_constants(namespace, context)
      return cached.clone unless cached.nil?
      skip = []
      result = []
      bases = context.split('::')
      while bases.length > 0
        built = bases.join('::')
        fqns = qualify(namespace, built)
        visibility = [:public]
        visibility.push :private if fqns == context
        result.concat inner_get_constants(fqns, visibility, skip)
        bases.pop
      end
      fqns = qualify(namespace, '')
      visibility = [:public]
      visibility.push :private if fqns == context
      result.concat inner_get_constants(fqns, visibility, skip)
      cache.set_constants(namespace, context, result)
      result
    end

    # Get a fully qualified namespace name. This method will start the search
    # in the specified context until it finds a match for the name.
    #
    # @param namespace [String] The namespace to match
    # @param context [String] The context to search
    # @return [String]
    def qualify namespace, context = ''
      # @todo The return for self might work better elsewhere
      return qualify(context) if namespace == 'self'
      cached = cache.get_qualified_namespace(namespace, context)
      return cached.clone unless cached.nil?
      result = inner_qualify(namespace, context, [])
      cache.set_qualified_namespace(namespace, context, result)
      result
    end

    def fragment_at(location)
      @sources.each do |source|
        return source.fragment_at(location.range.start.line, location.range.start.column) if source.filename == location.filename
      end
      nil
    end

    # @deprecated Use #qualify instead
    # @param namespace [String]
    # @param context [String]
    # @return [String]
    def find_fully_qualified_namespace namespace, context = ''
      qualify namespace, context
    end

    # Get an array of instance variable pins defined in specified namespace
    # and scope.
    #
    # @param namespace [String] A fully qualified namespace
    # @param scope [Symbol] :instance or :class
    # @return [Array<Solargraph::Pin::InstanceVariable>]
    def get_instance_variable_pins(namespace, scope = :instance)
      store.get_instance_variables(namespace, scope)
    end

    # Get an array of class variable pins for a namespace.
    #
    # @param namespace [String] A fully qualified namespace
    # @return [Array<Solargraph::Pin::ClassVariable>]
    def get_class_variable_pins(namespace)
      prefer_non_nil_variables(store.get_class_variables(namespace))
    end

    # @return [Array<Solargraph::Pin::Base>]
    def get_symbols
      store.get_symbols
    end

    # @todo Make this better
    def get_source filename
      @sources.each do |s|
        return s if s.filename == filename
      end
      nil
    end

    # @return [Array<Solargraph::Pin::GlobalVariable>]
    def get_global_variable_pins
      globals = []
      @sources.each do |s|
        globals.concat s.global_variable_pins
      end
      globals
    end

    # Get an array of methods available in a particular context.
    #
    # @param fqns [String] The fully qualified namespace to search for methods
    # @param scope [Symbol] :class or :instance
    # @param visibility [Array<Symbol>] :public, :protected, and/or :private
    # @param deep [Boolean] True to include superclasses, mixins, etc.
    # @return [Array<Solargraph::Pin::Base>]
    def get_methods fqns, scope: :instance, visibility: [:public], deep: true
      cached = cache.get_methods(fqns, scope, visibility, deep)
      return cached.clone unless cached.nil?
      result = []
      skip = []
      if fqns == ''
        domains.each do |domain|
          type = ComplexType.parse(domain).first
          result.concat inner_get_methods(type.name, type.scope, [:public], deep, skip)
        end
        result.concat inner_get_methods(fqns, :class, visibility, deep, skip)
        result.concat inner_get_methods(fqns, :instance, visibility, deep, skip)
        result.concat inner_get_methods('Kernel', :instance, visibility, deep, skip)
      else
        result.concat inner_get_methods(fqns, scope, visibility, deep, skip)
      end
      live = live_map.get_methods(fqns, '', scope.to_s, visibility.include?(:private))
      unless live.empty?
        exist = result.map(&:name)
        result.concat live.reject{|p| exist.include?(p.name)}
      end
      cache.set_methods(fqns, scope, visibility, deep, result)
      result
    end

    # Get an array of public methods for a complex type.
    #
    # @param type [Solargraph::ComplexType]
    # @param context [String]
    # @return [Array<Solargraph::Pin::Base>]
    def get_complex_type_methods type, context = ''
      return [] if type.undefined? or type.void?
      result = []
      if type.duck_type?
        type.select(&:duck_type?).each do |t|
          result.push Pin::DuckMethod.new(nil, t.tag[1..-1])
        end
      else
        unless type.nil? or type.name == 'void'
          namespace = qualify(type.namespace, context)
          if ['Class', 'Module'].include?(namespace) and !type.subtypes.empty?
            subtype = qualify(type.subtypes.first.name, context)
            result.concat get_methods(subtype, scope: :class)
          end
          visibility = [:public]
          visibility.push :private, :protected if namespace == context
          result.concat get_methods(namespace, scope: type.scope, visibility: visibility)
        end
      end
      result
    end

    # Get a stack of method pins for a method name in a namespace. The order
    # of the pins corresponds to the ancestry chain, with highest precedence
    # first.
    #
    # @example
    #   api_map.get_method_stack('Subclass', 'method_name')
    #     #=> [ <Subclass#method_name pin>, <Superclass#method_name pin> ]
    #
    # @param fqns [String]
    # @param name [String]
    # @param scope [Symbol] :instance or :class
    # @return [Array<Solargraph::Pin::Base>]
    def get_method_stack fqns, name, scope: :instance
      # @todo Caches don't work on this query
      # cached = cache.get_method_stack(fqns, name, scope)
      # return cached.clone unless cached.nil?
      result = get_methods(fqns, scope: scope, visibility: [:private, :protected, :public]).select{|p| p.name == name}
      # cache.set_method_stack(fqns, name, scope, result)
      result
    end

    # Get an array of all suggestions that match the specified path.
    #
    # @param path [String] The path to find
    # @return [Array<Solargraph::Pin::Base>]
    def get_path_suggestions path
      return [] if path.nil?
      result = []
      result.concat store.get_path_pins(path)
      if result.empty?
        lp = live_map.get_path_pin(path)
        result.push lp unless lp.nil?
      end
      result
    end

    # Get a list of documented paths that match the query.
    #
    # @example
    #   api_map.query('str') # Results will include `String` and `Struct`
    #
    # @param query [String] The text to match
    # @return [Array<String>]
    def search query
      rake_yard(store) if @yard_stale
      @yard_stale = false
      found = []
      code_object_paths.each do |k|
        if found.empty? or (query.include?('.') or query.include?('#')) or !(k.include?('.') or k.include?('#'))
          found.push k if k.downcase.include?(query.downcase)
        end
      end
      found
    end

    # Get YARD documentation for the specified path.
    #
    # @example
    #   api_map.document('String#split')
    #
    # @param path [String] The path to find
    # @return [Array<YARD::CodeObject::Base>]
    def document path
      rake_yard(store) if @yard_stale
      @yard_stale = false
      docs = []
      docs.push code_object_at(path) unless code_object_at(path).nil?
      docs
    end

    # Get an array of all symbols in the workspace that match the query.
    #
    # @param query [String]
    # @return [Array<Pin::Base>]
    def query_symbols query
      result = []
      @sources.each do |s|
        result.concat s.query_symbols(query)
      end
      result
    end

    # @param location [Solargraph::Source::Location]
    # @return [Solargraph::Pin::Base]
    def locate_pin location
      @sources.each do |source|
        pin = source.locate_pin(location)
        return pin unless pin.nil?
      end
      nil
    end

    # @return [Array<String>]
    def unresolved_requires
      yard_map.unresolved_requires
    end

    private

    # @return [ApiMap::Store]
    def store
      @store ||= ApiMap::Store.new(@sources, yard_map.pins)
    end

    # @return [void]
    def refresh_store_and_maps
      @yard_stale = true
      @live_map = Solargraph::LiveMap.new(self)
      store.update_yard(yard_map.pins) if yard_map.change(required)
      cache.clear
      @stime = Time.now
    end

    # @return [void]
    def update_store_and_maps
      @yard_stale = true
      store.remove *(current_workspace_sources.reject{ |s| workspace.sources.include?(s) })
      @sources = workspace.sources
      @sources.push @virtual_source unless @virtual_source.nil?
      store.update *(@sources.select{ |s| @stime.nil? or s.stime > @stime })
      store.update_yard(yard_map.pins) if yard_map.change(required)
      cache.clear
      @stime = Time.now
    end

    # @return [void]
    def process_virtual
      map_source @virtual_source unless @virtual_source.nil?
      if yard_map.change(required)
        store.update_yard(yard_map.pins)
      end
      cache.clear
    end

    # @param source [Solargraph::Source]
    # @return [void]
    def map_source source
      store.update source
      path_macros.merge! source.path_macros
    end

    # @return [Solargraph::ApiMap::Cache]
    def cache
      @cache ||= Cache.new
    end

    # @param fqns [String] A fully qualified namespace
    # @param scope [Symbol] :class or :instance
    # @param visibility [Array<Symbol>] :public, :protected, and/or :private
    # @param deep [Boolean]
    # @param skip [Array<String>]
    # @return [Array<Pin::Base>]
    def inner_get_methods fqns, scope, visibility, deep, skip
      reqstr = "#{fqns}|#{scope}|#{visibility.sort}|#{deep}"
      return [] if skip.include?(reqstr)
      skip.push reqstr
      result = []
      result.concat store.get_attrs(fqns, scope)
      result.concat store.get_methods(fqns, scope: scope, visibility: visibility)
      if deep
        sc = store.get_superclass(fqns)
        unless sc.nil?
          fqsc = qualify(sc, fqns)
          sc_visi = [:public]
          sc_visi.push :protected if visibility.include?(:protected)
          result.concat inner_get_methods(fqsc, scope, sc_visi, true, skip) unless fqsc.nil?
        end
        if scope == :instance
          store.get_includes(fqns).each do |im|
            fqim = qualify(im, fqns)
            result.concat inner_get_methods(fqim, scope, visibility, deep, skip) unless fqim.nil?
          end
          result.concat inner_get_methods('Object', :instance, [:public], deep, skip) unless fqns == 'Object'
        else
          store.get_extends(fqns).each do |em|
            fqem = qualify(em, fqns)
            result.concat inner_get_methods(fqem, :instance, visibility, deep, skip) unless fqem.nil?
          end
          type = get_namespace_type(fqns)
          result.concat inner_get_methods('Class', :instance, fqns == '' ? [:public] : visibility, deep, skip) if type == :class
          result.concat inner_get_methods('Module', :instance, fqns == '' ? [:public] : visibility, deep, skip) #if type == :module
        end
      end
      result
    end

    # @param fqns [String]
    # @param visibility [Array<Symbol>]
    # @param skip [Array<String>]
    # @return [Array<Pin::Base>]
    def inner_get_constants fqns, visibility, skip
      return [] if skip.include?(fqns)
      skip.push fqns
      result = []
      result.concat store.get_constants(fqns, visibility)
      store.get_includes(fqns).each do |is|
        fqis = qualify(is, fqns)
        result.concat inner_get_constants(fqis, [:public], skip) unless fqis.nil?
      end
      result.concat live_map.get_constants(fqns)
      result
    end

    # Require extensions for the experimental plugin architecture. Any
    # installed gem with a name that starts with "solargraph-" is considered
    # an extension.
    #
    # @return [void]
    def require_extensions
      Gem::Specification.all_names.select{|n| n.match(/^solargraph\-[a-z0-9_\-]*?\-ext\-[0-9\.]*$/)}.each do |n|
        STDERR.puts "Loading extension #{n}"
        require n.match(/^(solargraph\-[a-z0-9_\-]*?\-ext)\-[0-9\.]*$/)[1]
      end
    end

    # @return [Hash]
    def path_macros
      @path_macros ||= {}
    end

    # @return [Array<Solargraph::Source>]
    def current_workspace_sources
      @sources - [@virtual_source]
    end

    # @param name [String]
    # @param root [String]
    # @param skip [Array<String>]
    # @return [String]
    def inner_qualify name, root, skip
      return nil if name.nil?
      return nil if skip.include?(root)
      skip.push root
      if name == ''
        if root == ''
          return ''
        else
          return inner_qualify(root, '', skip)
        end
      else
        if (root == '')
          return name if store.namespace_exists?(name)
          # @todo What to do about the @namespace_includes stuff above?
        else
          roots = root.to_s.split('::')
          while roots.length > 0
            fqns = roots.join('::') + '::' + name
            return fqns if store.namespace_exists?(fqns)
            roots.pop
          end
          return name if store.namespace_exists?(name)
        end
      end
      live_map.get_fqns(name, root)
    end

    # Get the namespace's type (Class or Module).
    #
    # @param fqns [String] A fully qualified namespace
    # @return [Symbol] :class, :module, or nil
    def get_namespace_type fqns
      return nil if fqns.nil?
      pin = store.get_path_pins(fqns).first
      return nil if pin.nil?
      pin.type
    end

    # Get a YardMap associated with the current workspace.
    #
    # @return [Solargraph::YardMap]
    def yard_map
      @yard_map ||= Solargraph::YardMap.new(required: required, workspace: workspace)
    end

    # Sort an array of pins to put nil or undefined variables last.
    #
    # @param pins [Array<Solargraph::Pin::Base>]
    # @return [Array<Solargraph::Pin::Base>]
    def prefer_non_nil_variables pins
      result = []
      nil_pins = []
      pins.each do |pin|
        if pin.variable? and pin.nil_assignment?
          nil_pins.push pin
        else
          result.push pin
        end
      end
      result + nil_pins
    end
  end
end
