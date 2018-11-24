require 'rubygems'
require 'set'

module Solargraph
  # An aggregate provider for information about workspaces, sources, gems, and
  # the Ruby core.
  #
  class ApiMap
    autoload :Cache,        'solargraph/api_map/cache'
    autoload :SourceToYard, 'solargraph/api_map/source_to_yard'
    autoload :Store,        'solargraph/api_map/store'

    include Solargraph::ApiMap::SourceToYard

    # Get a LiveMap associated with the current workspace.
    #
    # @return [Solargraph::LiveMap]
    attr_reader :live_map

    # @return [Array<String>]
    attr_reader :unresolved_requires

    # @param pins [Array<Solargraph::Pin::Base>]
    # def initialize workspace = Solargraph::Workspace.new(nil)
    def initialize pins: []
      # @todo Extensions don't work yet
      # require_extensions
      @source_map_hash = {}
      @cache = Cache.new
      @mutex = Mutex.new
      index pins
    end

    # @param pins [Array<Pin::Base>]
    # @return [self]
    def index pins
      @mutex.synchronize {
        @source_map_hash.clear
        @cache.clear
        @store = Store.new(pins + YardMap.new.pins)
        @unresolved_requires = []
      }
      resolved = resolve_method_aliases
      unless resolved.nil?
        @mutex.synchronize { @store = Store.new(resolved) }
      end
      self
    end

    # @param source [Source]
    # @return [self]
    def map source
      catalog Bundle.new(opened: [source])
      self
    end

    def named_macro name
      store.named_macros[name]
    end

    # Catalog a workspace. Additional sources that need to be mapped can be
    # included in an optional array.
    #
    # @param bundle [Bundle]
    # @return [self]
    def catalog bundle
      new_map_hash = {}
      unmerged = false
      bundle.sources.each do |source|
        if source_map_hash.has_key?(source.filename)
          if source_map_hash[source.filename].code == source.code
            new_map_hash[source.filename] = source_map_hash[source.filename]
          else
            map = Solargraph::SourceMap.map(source)
            if source_map_hash[source.filename].try_merge!(map)
              new_map_hash[source.filename] = source_map_hash[source.filename]
            else
              new_map_hash[source.filename] = map
              unmerged = true
            end
          end
        else
          map = Solargraph::SourceMap.map(source)
          new_map_hash[source.filename] = map
          unmerged = true
        end
      end
      return self unless unmerged
      pins = []
      reqs = []
      # @param map [SourceMap]
      new_map_hash.values.each do |map|
        pins.concat map.pins
        reqs.concat map.requires.map(&:name)
      end
      reqs.concat bundle.workspace.config.required
      unless bundle.workspace.require_paths.empty?
        reqs.delete_if do |r|
          result = false
          bundle.workspace.require_paths.each do |l|
            if new_map_hash.keys.include?(File.join(l, "#{r}.rb"))
              result = true
              break
            end
          end
          result
        end
      end
      yard_map.change(reqs)
      new_store = Store.new(pins + yard_map.pins)
      @mutex.synchronize {
        @cache.clear
        @source_map_hash = new_map_hash
        @store = new_store
        @unresolved_requires = yard_map.unresolved_requires
      }
      resolved = resolve_method_aliases
      unless resolved.nil?
        @mutex.synchronize { @store = Store.new(resolved) }
      end
      self
    end

    # @param filename [String]
    # @param position [Position]
    # @return [Source::Cursor]
    def cursor_at filename, position
      raise "File not found: #{filename}" unless source_map_hash.has_key?(filename)
      source_map_hash[filename].cursor_at(position)
    end

    # Get a clip by filename and position.
    #
    # @param filename [String]
    # @param position [Position]
    # @return [SourceMap::Clip]
    def clip_at filename, position
      SourceMap::Clip.new(self, cursor_at(filename, position))
    end

    # Create an ApiMap with a workspace in the specified directory.
    #
    # @param directory [String]
    # @return [ApiMap]
    def self.load directory
      # @todo How should this work?
      api_map = self.new #(Solargraph::Workspace.new(directory))
      workspace = Solargraph::Workspace.new(directory)
      api_map.catalog Bundle.new(workspace: workspace)
      api_map
    end

    # @return [Array<Solargraph::Pin::Base>]
    def pins
      store.pins
    end

    # An array of suggestions based on Ruby keywords (`if`, `end`, etc.).
    #
    # @return [Array<Solargraph::Pin::Keyword>]
    def self.keywords
      @keywords ||= CoreFills::KEYWORDS.map{ |s|
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
    # @param namespace [String, nil] The namespace to match
    # @param context [String] The context to search
    # @return [String]
    def qualify namespace, context = ''
      # @todo The return for self might work better elsewhere
      return nil if namespace.nil?
      return qualify(context) if namespace == 'self'
      cached = cache.get_qualified_namespace(namespace, context)
      return cached.clone unless cached.nil?
      # result = inner_qualify(namespace, context, [])
      # result = result[2..-1] if !result.nil? && result.start_with?('::')
      if namespace.start_with?('::')
        result = inner_qualify(namespace[2..-1], '', [])
      else
        result = inner_qualify(namespace, context, [])
      end
      cache.set_qualified_namespace(namespace, context, result)
      result
    end

    # Get an array of instance variable pins defined in specified namespace
    # and scope.
    #
    # @param namespace [String] A fully qualified namespace
    # @param scope [Symbol] :instance or :class
    # @return [Array<Solargraph::Pin::InstanceVariable>]
    def get_instance_variable_pins(namespace, scope = :instance)
      result = []
      result.concat store.get_instance_variables(namespace, scope)
      sc = qualify(store.get_superclass(namespace), namespace)
      until sc.nil?
        result.concat store.get_instance_variables(sc, scope)
        sc = qualify(store.get_superclass(sc), sc)
      end
      result
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

    # @return [Array<Solargraph::Pin::GlobalVariable>]
    def get_global_variable_pins
      # @todo Slow version
      pins.select{|p| p.kind == Pin::GLOBAL_VARIABLE}
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
        # @todo Implement domains
        # domains.each do |domain|
        #   type = ComplexType.parse(domain).first
        #   result.concat inner_get_methods(type.name, type.scope, [:public], deep, skip)
        # end
        result.concat inner_get_methods(fqns, :class, visibility, deep, skip)
        result.concat inner_get_methods(fqns, :instance, visibility, deep, skip)
        result.concat inner_get_methods('Kernel', :instance, visibility, deep, skip)
      else
        result.concat inner_get_methods(fqns, scope, visibility, deep, skip)
      end
      # live = live_map.get_methods(fqns, '', scope.to_s, visibility.include?(:private))
      # unless live.empty?
      #   exist = result.map(&:name)
      #   result.concat live.reject{|p| exist.include?(p.name)}
      # end
      cache.set_methods(fqns, scope, visibility, deep, result)
      result
    end

    # Get an array of public methods for a complex type.
    #
    # @todo It might be reasonable to assume that the type argument is fully
    #   qualified, which would eliminate the need for a context argument.
    #
    # @param type [Solargraph::ComplexType]
    # @param context [String]
    # @param internal [Boolean] True to include private methods
    # @return [Array<Solargraph::Pin::Base>]
    def get_complex_type_methods type, context = '', internal = false
      return [] if type.undefined? || type.void?
      result = []
      if type.duck_type?
        type.select(&:duck_type?).each do |t|
          result.push Pin::DuckMethod.new(nil, t.tag[1..-1])
        end
        result.concat get_methods('Object')
      else
        unless type.nil? || type.name == 'void'
          namespace = qualify(type.namespace, context)
          visibility = [:public]
          if namespace == context || super_and_sub?(namespace, context)
            visibility.push :protected
            visibility.push :private if internal
          end
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
      # @todo This cache is still causing problems, but only when using
      #   Solargraph on Solargraph itself.
      # cached = cache.get_method_stack(fqns, name, scope)
      # return cached unless cached.nil?
      result = get_methods(fqns, scope: scope, visibility: [:private, :protected, :public]).select{|p| p.name == name}
      # cache.set_method_stack(fqns, name, scope, result)
      # result
    end

    # Get an array of all suggestions that match the specified path.
    #
    # @deprecated Use #get_path_pins instead.
    #
    # @param path [String] The path to find
    # @return [Array<Solargraph::Pin::Base>]
    def get_path_suggestions path
      return [] if path.nil?
      result = []
      result.concat store.get_path_pins(path)
      # if result.empty?
      #   lp = live_map.get_path_pin(path)
      #   result.push lp unless lp.nil?
      # end
      result
    end

    # Get an array of pins that match the specified path.
    #
    # @param path [String]
    # @return [Array<Pin::Base>]
    def get_path_pins path
      get_path_suggestions(path)
    end

    # Get a list of documented paths that match the query.
    #
    # @example
    #   api_map.query('str') # Results will include `String` and `Struct`
    #
    # @param query [String] The text to match
    # @return [Array<String>]
    def search query
      rake_yard(store)
      found = []
      code_object_paths.each do |k|
        if found.empty? || (query.include?('.') || query.include?('#')) || !(k.include?('.') || k.include?('#'))
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
      rake_yard(store)
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
      source_map_hash.values.each do |s|
        result.concat s.query_symbols(query)
      end
      result
    end

    # @param location [Solargraph::Location]
    # @return [Solargraph::Pin::Base]
    def locate_pin location
      return nil if location.nil? || !source_map_hash.has_key?(location.filename)
      source_map_hash[location.filename].locate_pin(location)
    end

    # @raise [FileNotFoundError] if the cursor's file is not in the ApiMap
    # @param cursor [Source::Cursor]
    # @return [SourceMap::Clip]
    def clip cursor
      raise FileNotFoundError, "ApiMap did not catalog #{cursor.filename}" unless source_map_hash.has_key?(cursor.filename)
      SourceMap::Clip.new(self, cursor)
    end

    # Get an array of document symbols from a file.
    #
    # @param filename [String]
    # @return [Array<Pin::Symbol>]
    def document_symbols filename
      return [] unless source_map_hash.has_key?(filename) # @todo Raise error?
      source_map_hash[filename].document_symbols
    end

    # Get a source map by filename.
    #
    # @param filename [String]
    # @return [SourceMap]
    def source_map filename
      raise FileNotFoundError, "Source map for `#{filename}` not found" unless source_map_hash.has_key?(filename)
      source_map_hash[filename]
    end

    private

    def yard_map
      @yard_map ||= YardMap.new
    end

    # A hash of source maps with filename keys.
    #
    # @return [Hash{String => SourceMap}]
    def source_map_hash
      @mutex.synchronize {
        @source_map_hash
      }
    end

    # @return [ApiMap::Store]
    def store
      @mutex.synchronize {
        @store
      }
    end

    # @return [Solargraph::ApiMap::Cache]
    def cache
      @mutex.synchronize {
        @cache
      }
    end

    # @param fqns [String] A fully qualified namespace
    # @param scope [Symbol] :class or :instance
    # @param visibility [Array<Symbol>] :public, :protected, and/or :private
    # @param deep [Boolean]
    # @param skip [Array<String>]
    # @param no_core [Boolean] Skip core classes if true
    # @return [Array<Pin::Base>]
    def inner_get_methods fqns, scope, visibility, deep, skip, no_core = false
      return [] if no_core && fqns =~ /^(Object|BasicObject|Class|Module|Kernel)$/
      reqstr = "#{fqns}|#{scope}|#{visibility.sort}|#{deep}"
      return [] if skip.include?(reqstr)
      skip.push reqstr
      result = []
      result.concat store.get_methods(fqns, scope: scope, visibility: visibility).sort{ |a, b| a.name <=> b.name }
      if deep
        sc = store.get_superclass(fqns)
        unless sc.nil?
          fqsc = qualify(sc, fqns.split('::')[0..-2].join('::'))
          result.concat inner_get_methods(fqsc, scope, visibility, true, skip, true) unless fqsc.nil?
        end
        if scope == :instance
          store.get_includes(fqns).reverse.each do |im|
            fqim = qualify(im, fqns)
            result.concat inner_get_methods(fqim, scope, visibility, deep, skip, true) unless fqim.nil?
          end
          result.concat inner_get_methods('Object', :instance, [:public], deep, skip, no_core)
        else
          store.get_extends(fqns).reverse.each do |em|
            fqem = qualify(em, fqns)
            result.concat inner_get_methods(fqem, :instance, visibility, deep, skip, true) unless fqem.nil?
          end
          unless no_core || fqns.empty?
            type = get_namespace_type(fqns)
            result.concat inner_get_methods('Class', :instance, visibility, deep, skip, no_core) if type == :class
            result.concat inner_get_methods('Module', :instance,visibility, deep, skip, no_core)
          end
        end
        store.domains(fqns).each do |d|
          dt = ComplexType.parse(d)
          result.concat inner_get_methods(dt.namespace, dt.scope, [:public], deep, skip)
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
      result.concat store.get_constants(fqns, visibility).sort{ |a, b| a.name <=> b.name }
      store.get_includes(fqns).each do |is|
        fqis = qualify(is, fqns)
        result.concat inner_get_constants(fqis, [:public], skip) unless fqis.nil?
      end
      # result.concat live_map.get_constants(fqns)
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
      # live_map.get_fqns(name, root)
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

    # Sort an array of pins to put nil or undefined variables last.
    #
    # @param pins [Array<Solargraph::Pin::Base>]
    # @return [Array<Solargraph::Pin::Base>]
    def prefer_non_nil_variables pins
      result = []
      nil_pins = []
      pins.each do |pin|
        if pin.variable? && pin.nil_assignment?
          nil_pins.push pin
        else
          result.push pin
        end
      end
      result + nil_pins
    end

    # Check if a class is a superclass of another class.
    #
    # @param sup [String] The superclass
    # @param sub [String] The subclass
    # @return [Boolean]
    def super_and_sub?(sup, sub)
      fqsup = qualify(sup)
      cls = qualify(store.get_superclass(sub), sub)
      until cls.nil?
        return true if cls == fqsup
        cls = qualify(store.get_superclass(cls), cls)
      end
      false
    end

    # @return [Array<Pin::Base>, nil]
    def resolve_method_aliases
      aliased = false
      result = pins.map do |pin|
        next pin unless pin.is_a?(Pin::MethodAlias)
        origin = get_method_stack(pin.namespace, pin.original, scope: pin.scope).select{|pin| pin.class == Pin::Method}.first
        next pin if origin.nil?
        aliased = true
        Pin::Method.new(pin.location, pin.namespace, pin.name, origin.comments, origin.scope, origin.visibility, origin.parameters)
      end
      return nil unless aliased
      result
    end
  end
end
