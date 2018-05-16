require 'rubygems'
require 'set'
require 'time'

module Solargraph
  class ApiMap
    autoload :Cache,        'solargraph/api_map/cache'
    autoload :SourceToYard, 'solargraph/api_map/source_to_yard'
    autoload :Completion,   'solargraph/api_map/completion'
    autoload :Probe,        'solargraph/api_map/probe'
    autoload :Store,        'solargraph/api_map/store'
    autoload :TypeMethods,  'solargraph/api_map/type_methods'

    include Solargraph::ApiMap::SourceToYard
    include CoreFills
    include TypeMethods

    # The workspace to analyze and process.
    #
    # @return [Solargraph::Workspace]
    attr_reader :workspace

    # @return [ApiMap::Store]
    attr_reader :store

    # Get a LiveMap associated with the current workspace.
    #
    # @return [Solargraph::LiveMap]
    attr_reader :live_map

    # @param workspace [Solargraph::Workspace]
    def initialize workspace = Solargraph::Workspace.new(nil)
      @workspace = workspace
      require_extensions
      @virtual_source = nil
      @yard_stale = true
      # process_maps
      @sources = workspace.sources
      refresh_store_and_maps
    end

    # Create an ApiMap with a workspace in the specified directory.
    #
    # @return [ApiMap]
    def self.load directory
      self.new(Solargraph::Workspace.new(directory))
    end

    def pins
      store.pins
    end

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

    # Get a YardMap associated with the current workspace.
    #
    # @return [Solargraph::YardMap]
    def yard_map
      # refresh
      if @yard_map.required.to_set != required.to_set
        @yard_map = Solargraph::YardMap.new(required: required, workspace: workspace)
      end
      @yard_map
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

    # Refresh the ApiMap.
    #
    # @param force [Boolean] Perform a refresh even if the map is not "stale."
    def refresh force = false
      return unless @force or changed?
      if force
        @api_map = ApiMap::Store.new(@sources)
      else
        store.remove *(current_workspace_sources.reject{ |s| workspace.sources.include?(s) })
        @sources = workspace.sources
        @sources.push @virtual_source unless @virtual_source.nil?
        store.update *(@sources.select{ |s| @stime.nil? or s.stime > @stime })
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
      result
    end

    # Get a fully qualified namespace name. This method will start the search
    # in the specified context until it finds a match for the name.
    #
    # @param namespace [String] The namespace to match
    # @param context [String] The context to search
    # @return [String]
    def qualify namespace, context = ''
      inner_qualify namespace, context, []
    end

    # @deprecated Use #qualify instead
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
      prefer_non_nil_variables(@cvar_pins[namespace] || [])
    end

    # @return [Array<Solargraph::Pin::Base>]
    def get_symbols
      store.get_symbols
    end

    # @return [Array<Solargraph::Pin::GlobalVariable>]
    def get_global_variable_pins
      globals = []
      @sources.each do |s|
        globals.concat s.global_variable_pins
      end
      globals
    end

    def get_methods fqns, scope: :instance, visibility: [:public], deep: true
      result = []
      skip = []
      if fqns == ''
        domains.each do |domain|
          namespace, scope = extract_namespace_and_scope(domain)
          result.concat inner_get_methods(namespace, scope, [:public], deep, skip)
        end
        result.concat inner_get_methods(fqns, :class, visibility, deep, skip)
        result.concat inner_get_methods(fqns, :instance, visibility, deep, skip)
        result.concat inner_get_methods('Kernel', :instance, visibility, deep, skip)
      else
        result.concat inner_get_methods(fqns, scope, visibility, deep, skip)
      end
      result
    end

    # @param fragment [Solargraph::Source::Fragment]
    # @return [ApiMap::Completion]
    def complete fragment
      return Completion.new([], fragment.whole_word_range) if fragment.string? or fragment.comment?
      result = []
      if !fragment.signature.include?('.') and !fragment.base_literal?
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
            result.concat prefer_non_nil_variables(fragment.locals)
            result.concat get_methods(fragment.namespace, scope: fragment.scope, visibility: [:public, :private, :protected])
            result.concat get_methods('Kernel')
            result.concat ApiMap.keywords
          end
          result.concat get_constants(fragment.base, fragment.namespace)
        end
      else
        if fragment.base_literal?
          pin = get_path_suggestions(fragment.base_literal).select{|pin| pin.kind == Pin::NAMESPACE}.first
          unless pin.nil?
            if fragment.base.empty?
              result.concat get_methods(pin.path)
            else
              type = probe.infer_signature_type("#{pin.path}.new.#{fragment.base}", pin, fragment.locals)
              unless type.nil?
                namespace, scope = extract_namespace_and_scope(type)
                result.concat get_methods(namespace, scope: scope)
              end
            end
          end
        elsif fragment.signature.include?('::') and !fragment.signature.include?('.')
          result.concat get_constants(fragment.base, fragment.namespace)
        else
          type = probe.infer_signature_type(fragment.base, fragment.named_path, fragment.locals)
          unless type.nil?
            namespace, scope = extract_namespace_and_scope(type)
            result.concat get_methods(namespace, scope: scope)
          end
        end
      end
      frag_start = fragment.word.to_s.downcase
      filtered = result.uniq(&:identifier).select{|s| s.name.downcase.start_with?(frag_start) and (s.kind != Pin::METHOD or s.name.match(/^[a-z0-9_]*(\!|\?|=)?$/i))}.sort_by.with_index{ |x, idx| [x.name, idx] }
      Completion.new(filtered, fragment.whole_word_range)
    end

    # @param fragment [Solargraph::Source::Fragment]
    # @return [Array<Solargraph::Pin::Base>]
    def define fragment
      return [] if fragment.string? or fragment.comment?
      if fragment.base_literal?
        probe.infer_signature_pins fragment.whole_signature, Pin::ProxyMethod.new(fragment.base_literal), fragment.locals
      else
        probe.infer_signature_pins fragment.whole_signature, fragment.named_path, fragment.locals
      end
    end

    # Infer a return type from a fragment. This method will attempt to resolve
    # signatures.
    #
    # @param fragment [Solargraph::Source::Fragment]
    # @return [String]
    def infer_type fragment
      return nil if fragment.string? or fragment.comment?
      probe.infer_signature_type fragment.whole_signature, fragment.named_path, fragment.locals
    end

    # Get an array of pins that describe the method being called by the
    # argument list where the fragment is located. This is useful for queries
    # that need to know what parameters the current method expects to receive.
    #
    # If the fragment is not inside an argument list, return an empty array.
    #
    # @param fragment [Solargraph::Source::Fragment]
    # @return [Array<Solargraph::Pin::Base>]
    def signify fragment
      return [] unless fragment.argument?
      return [] if fragment.recipient.whole_signature.nil? or fragment.recipient.whole_signature.empty?
      result = []
      if fragment.recipient.base_literal?
        result.concat probe.infer_signature_pins(fragment.recipient.whole_signature, Pin::ProxyMethod.new(fragment.recipient.base_literal), fragment.locals)
      else
        result.concat probe.infer_signature_pins(fragment.recipient.whole_signature, fragment.named_path, fragment.locals)
      end
      result.select{ |pin| pin.kind == Pin::METHOD }
    end

    # Get an array of all suggestions that match the specified path.
    #
    # @param path [String] The path to find
    # @return [Array<Solargraph::Pin::Base>]
    def get_path_suggestions path
      return [] if path.nil?
      result = []
      result.concat store.get_path_pins(path)
      result.concat yard_map.objects(path)
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
      rake_yard(@sources) if @yard_stale
      @yard_stale = false
      docs = []
      docs.push code_object_at(path) unless code_object_at(path).nil?
      docs.concat yard_map.document(path)
      docs
    end

    # Get an array of all symbols in the workspace that match the query.
    #
    # @return [Array<Pin::Base>]
    def query_symbols query
      result = []
      @sources.each do |s|
        result.concat s.query_symbols(query)
      end
      result
    end

    def locate_pin location
      @sources.each do |source|
        pin = source.locate_pin(location)
        unless pin.nil?
          # pin.resolve self
          return pin
        end
      end
      nil
    end

    # @return [Probe]
    def probe
      @probe ||= Probe.new(self)
    end

    private

    def refresh_store_and_maps
      @store = ApiMap::Store.new(@sources)
      @live_map = Solargraph::LiveMap.new(self)
      @yard_map = Solargraph::YardMap.new(required: required, workspace: workspace)
    end

    def process_virtual
      unless @virtual_source.nil?
        map_source @virtual_source
      end
    end

    # @param [Solargraph::Source]
    def map_source source
      store.update source
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
      reqstr = "#{fqns}|#{scope}|#{visibility.sort}|#{deep}"
      return [] if skip.include?(reqstr)
      skip.push reqstr
      result = []
      if scope == :instance
        result.concat store.get_attrs(fqns)
      end
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
          result.concat yard_map.get_instance_methods(fqns, visibility: visibility)
          result.concat inner_get_methods('Object', :instance, [:public], deep, skip) unless fqns == 'Object'
        else
          store.get_extends(fqns).each do |em|
            fqem = qualify(em, fqns)
            result.concat inner_get_methods(fqem, :instance, visibility, deep, skip) unless fqem.nil?
          end
          result.concat yard_map.get_methods(fqns, '', visibility: visibility)
          type = get_namespace_type(fqns)
          result.concat inner_get_methods('Class', :instance, fqns == '' ? [:public] : visibility, deep, skip) if type == :class
          result.concat inner_get_methods('Module', :instance, fqns == '' ? [:public] : visibility, deep, skip) if type == :module
        end
      end
      result
    end

    def inner_get_constants fqns, visibility, skip
      return [] if skip.include?(fqns)
      skip.push fqns
      result = []
      result.concat store.get_constants(fqns, visibility)
      result.concat yard_map.get_constants(fqns)
      store.get_includes(fqns).each do |is|
        fqis = qualify(is, fqns)
        result.concat inner_get_constants(fqis, [:public], skip) unless fqis.nil?
      end
      result
    end

    # Require extensions for the experimental plugin architecture. Any
    # installed gem with a name that starts with "solargraph-" is considered
    # an extension.
    #
    def require_extensions
      Gem::Specification.all_names.select{|n| n.match(/^solargraph\-[a-z0-9_\-]*?\-ext\-[0-9\.]*$/)}.each do |n|
        STDERR.puts "Loading extension #{n}"
        require n.match(/^(solargraph\-[a-z0-9_\-]*?\-ext)\-[0-9\.]*$/)[1]
      end
    end

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

    # @return [Hash]
    def path_macros
      @path_macros ||= {}
    end

    def current_workspace_sources
      @sources - [@virtual_source]
    end

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
      result = yard_map.find_fully_qualified_namespace(name, root)
      if result.nil?
        result = live_map.get_fqns(name, root)
      end
      result
    end

    # Get the namespace's type (Class or Module).
    #
    # @param [String] A fully qualified namespace
    # @return [Symbol] :class, :module, or nil
    def get_namespace_type fqns
      pin = store.get_path_pins(fqns).first
      return yard_map.get_namespace_type(fqns) if pin.nil?
      pin.type
    end
  end
end
