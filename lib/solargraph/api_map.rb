# frozen_string_literal: true

require 'rubygems'
require 'set'
require 'pathname'
require 'yard'
require 'yard-solargraph'

module Solargraph
  # An aggregate provider for information about workspaces, sources, gems, and
  # the Ruby core.
  #
  class ApiMap
    autoload :Cache,          'solargraph/api_map/cache'
    autoload :SourceToYard,   'solargraph/api_map/source_to_yard'
    autoload :Store,          'solargraph/api_map/store'
    autoload :BundlerMethods, 'solargraph/api_map/bundler_methods'

    include SourceToYard
    include BundlerMethods

    # @return [Array<String>]
    attr_reader :unresolved_requires

    # @param pins [Array<Solargraph::Pin::Base>]
    def initialize pins: []
      @source_map_hash = {}
      @cache = Cache.new
      @method_alias_stack = []
      index pins
    end

    # @param pins [Array<Pin::Base>]
    # @return [self]
    def index pins
      catalog Bench.new(pins: pins)
      self
    end

    # Map a single source.
    #
    # @param source [Source]
    # @return [self]
    def map source
      catalog Bench.new(opened: [source])
      self
    end

    # @param name [String]
    # @return [YARD::Tags::MacroDirective, nil]
    def named_macro name
      store.named_macros[name]
    end

    # Catalog a bench.
    #
    # @param bench [Bench]
    # @return [self]
    def catalog bench
      new_map_hash = {}
      # Bench always needs to be merged if it adds or removes sources
      merged = (bench.sources.length == source_map_hash.values.length)
      bench.sources.each do |source|
        if source_map_hash.key?(source.filename)
          if source_map_hash[source.filename].code == source.code && source_map_hash[source.filename].source.synchronized? && source.synchronized?
            new_map_hash[source.filename] = source_map_hash[source.filename]
          elsif !source.synchronized?
            new_map_hash[source.filename] = source_map_hash[source.filename]
            # @todo Smelly instance variable access
            new_map_hash[source.filename].instance_variable_set(:@source, source)
          else
            map = Solargraph::SourceMap.map(source)
            if source_map_hash[source.filename].try_merge!(map)
              new_map_hash[source.filename] = source_map_hash[source.filename]
            else
              new_map_hash[source.filename] = map
              merged = false
            end
          end
        else
          map = Solargraph::SourceMap.map(source)
          new_map_hash[source.filename] = map
          merged = false
        end
      end
      return self if bench.pins.empty? && @store && merged
      implicit.clear
      pins = []
      reqs = Set.new
      # @param map [SourceMap]
      new_map_hash.values.each do |map|
        pins.concat map.pins
        reqs.merge map.requires.map(&:name)
      end
      pins.concat bench.pins
      reqs.merge bench.workspace.config.required
      @required = reqs
      bench.opened.each do |src|
        implicit.merge new_map_hash[src.filename].environ
      end
      # implicit.merge Convention.for_global(self)
      local_path_hash.clear
      unless bench.workspace.require_paths.empty?
        file_keys = new_map_hash.keys
        workspace_path = Pathname.new(bench.workspace.directory)
        reqs.delete_if do |r|
          bench.workspace.require_paths.any? do |base|
            pn = workspace_path.join(base, "#{r}.rb").to_s
            if file_keys.include? pn
              local_path_hash[r] = pn
              true
            else
              false
            end
          end
        end
      end
      reqs.merge implicit.requires
      # pins.concat implicit.pins
      br = reqs.include?('bundler/require') ? require_from_bundle(bench.workspace.directory) : {}
      reqs.merge br.keys
      yard_map.change(reqs.to_a, br, bench.workspace.gemnames)
      new_store = Store.new(yard_map.pins + implicit.pins + pins)
      @cache.clear
      @source_map_hash = new_map_hash
      @store = new_store
      @unresolved_requires = yard_map.unresolved_requires
      workspace_filenames.clear
      workspace_filenames.concat bench.workspace.filenames
      @rebindable_method_names = nil
      store.block_pins.each { |blk| blk.rebind(self) }
      self
    end

    def required
      @required ||= Set.new
    end

    # @return [Environ]
    def implicit
      @implicit ||= Environ.new
    end

    # @return [Hash{String => String}]
    def local_path_hash
      @local_paths ||= {}
    end

    # @param filename [String]
    # @param position [Position, Array(Integer, Integer)]
    # @return [Source::Cursor]
    def cursor_at filename, position
      position = Position.normalize(position)
      raise FileNotFoundError, "File not found: #{filename}" unless source_map_hash.has_key?(filename)
      source_map_hash[filename].cursor_at(position)
    end

    # Get a clip by filename and position.
    #
    # @param filename [String]
    # @param position [Position, Array(Integer, Integer)]
    # @return [SourceMap::Clip]
    def clip_at filename, position
      position = Position.normalize(position)
      SourceMap::Clip.new(self, cursor_at(filename, position))
    end

    # Create an ApiMap with a workspace in the specified directory.
    #
    # @param directory [String]
    # @return [ApiMap]
    def self.load directory
      api_map = self.new
      workspace = Solargraph::Workspace.new(directory)
      api_map.catalog Bench.new(workspace: workspace)
      api_map
    end

    # @return [Array<Solargraph::Pin::Base>]
    def pins
      store.pins
    end

    def rebindable_method_names
      @rebindable_method_names ||= begin
        result = yard_map.rebindable_method_names
        source_maps.each do |map|
          result.merge map.rebindable_method_names
        end
        result
      end
    end

    # An array of pins based on Ruby keywords (`if`, `end`, etc.).
    #
    # @return [Array<Solargraph::Pin::Keyword>]
    def keyword_pins
      store.pins_by_class(Pin::Keyword)
    end

    # An array of namespace names defined in the ApiMap.
    #
    # @return [Set<String>]
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
    # @param contexts [Array<String>] The contexts
    # @return [Array<Solargraph::Pin::Base>]
    def get_constants namespace, *contexts
      namespace ||= ''
      contexts.push '' if contexts.empty?
      cached = cache.get_constants(namespace, contexts)
      return cached.clone unless cached.nil?
      skip = Set.new
      result = []
      contexts.each do |context|
        fqns = qualify(namespace, context)
        visibility = [:public]
        visibility.push :private if fqns == context
        result.concat inner_get_constants(fqns, visibility, skip)
      end
      cache.set_constants(namespace, contexts, result)
      result
    end

    # Get a fully qualified namespace name. This method will start the search
    # in the specified context until it finds a match for the name.
    #
    # @param namespace [String, nil] The namespace to match
    # @param context [String] The context to search
    # @return [String]
    def qualify namespace, context = ''
      return namespace if ['self', nil].include?(namespace)
      cached = cache.get_qualified_namespace(namespace, context)
      return cached.clone unless cached.nil?
      result = if namespace.start_with?('::')
                 inner_qualify(namespace[2..-1], '', Set.new)
               else
                 inner_qualify(namespace, context, Set.new)
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
      used = [namespace]
      result.concat store.get_instance_variables(namespace, scope)
      sc = qualify_lower(store.get_superclass(namespace), namespace)
      until sc.nil? || used.include?(sc)
        used.push sc
        result.concat store.get_instance_variables(sc, scope)
        sc = qualify_lower(store.get_superclass(sc), sc)
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
      store.pins_by_class(Pin::GlobalVariable)
    end

    # Get an array of methods available in a particular context.
    #
    # @param fqns [String] The fully qualified namespace to search for methods
    # @param scope [Symbol] :class or :instance
    # @param visibility [Array<Symbol>] :public, :protected, and/or :private
    # @param deep [Boolean] True to include superclasses, mixins, etc.
    # @return [Array<Solargraph::Pin::Method>]
    def get_methods fqns, scope: :instance, visibility: [:public], deep: true
      cached = cache.get_methods(fqns, scope, visibility, deep)
      return cached.clone unless cached.nil?
      result = []
      skip = Set.new
      if fqns == ''
        # @todo Implement domains
        implicit.domains.each do |domain|
          type = ComplexType.try_parse(domain)
          next if type.undefined?
          result.concat inner_get_methods(type.name, type.scope, [:public], deep, skip)
        end
        result.concat inner_get_methods(fqns, :class, visibility, deep, skip)
        result.concat inner_get_methods(fqns, :instance, visibility, deep, skip)
        result.concat inner_get_methods('Kernel', :instance, visibility, deep, skip)
      else
        result.concat inner_get_methods(fqns, scope, visibility, deep, skip)
        result.concat inner_get_methods('Kernel', :instance, [:public], deep, skip) if visibility.include?(:private)
      end
      resolved = resolve_method_aliases(result, visibility)
      cache.set_methods(fqns, scope, visibility, deep, resolved)
      resolved
    end

    # Get an array of method pins for a complex type.
    #
    # The type's namespace and the context should be fully qualified. If the
    # context matches the namespace type or is a subclass of the type,
    # protected methods are included in the results. If protected methods are
    # included and internal is true, private methods are also included.
    #
    # @example
    #   api_map = Solargraph::ApiMap.new
    #   type = Solargraph::ComplexType.parse('String')
    #   api_map.get_complex_type_methods(type)
    #
    # @param type [Solargraph::ComplexType] The complex type of the namespace
    # @param context [String] The context from which the type is referenced
    # @param internal [Boolean] True to include private methods
    # @return [Array<Solargraph::Pin::Base>]
    def get_complex_type_methods type, context = '', internal = false
      # This method does not qualify the complex type's namespace because
      # it can cause conflicts between similar names, e.g., `Foo` vs.
      # `Other::Foo`. It still takes a context argument to determine whether
      # protected and private methods are visible.
      return [] if type.undefined? || type.void?
      result = []
      if type.duck_type?
        type.select(&:duck_type?).each do |t|
          result.push Pin::DuckMethod.new(name: t.tag[1..-1])
        end
        result.concat get_methods('Object')
      else
        unless type.nil? || type.name == 'void'
          visibility = [:public]
          if type.namespace == context || super_and_sub?(type.namespace, context)
            visibility.push :protected
            visibility.push :private if internal
          end
          result.concat get_methods(type.namespace, scope: type.scope, visibility: visibility)
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
    # @return [Array<Solargraph::Pin::Method>]
    def get_method_stack fqns, name, scope: :instance
      get_methods(fqns, scope: scope, visibility: [:private, :protected, :public]).select{|p| p.name == name}
    end

    # Get an array of all suggestions that match the specified path.
    #
    # @deprecated Use #get_path_pins instead.
    #
    # @param path [String] The path to find
    # @return [Array<Solargraph::Pin::Base>]
    def get_path_suggestions path
      return [] if path.nil?
      resolve_method_aliases store.get_path_pins(path)
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
    # @return [Array<YARD::CodeObjects::Base>]
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
    # @return [Array<Solargraph::Pin::Base>]
    def locate_pins location
      return [] if location.nil? || !source_map_hash.has_key?(location.filename)
      resolve_method_aliases source_map_hash[location.filename].locate_pins(location)
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
      resolve_method_aliases source_map_hash[filename].document_symbols
    end

    # @return [Array<SourceMap>]
    def source_maps
      source_map_hash.values
    end

    # Get a source map by filename.
    #
    # @param filename [String]
    # @return [SourceMap]
    def source_map filename
      raise FileNotFoundError, "Source map for `#{filename}` not found" unless source_map_hash.has_key?(filename)
      source_map_hash[filename]
    end

    # True if the specified file was included in a bundle, i.e., it's either
    # included in a workspace or open in a library.
    #
    # @param filename [String]
    def bundled? filename
      source_map_hash.keys.include?(filename)
    end

    # True if the specified file is included in the workspace.
    #
    # @param filename [String]
    def workspaced? filename
      workspace_filenames.include?(filename)
    end

    # @param location [Location]
    # @return [Location]
    def require_reference_at location
      map = source_map(location.filename)
      pin = map.requires.select { |pin| pin.location.range.contain?(location.range.start) }.first
      return nil if pin.nil?
      if local_path_hash.key?(pin.name)
        return Location.new(local_path_hash[pin.name], Solargraph::Range.from_to(0, 0, 0, 0))
      end
      yard_map.require_reference(pin.name)
    rescue FileNotFoundError
      nil
    end

    # Check if a class is a superclass of another class.
    #
    # @param sup [String] The superclass
    # @param sub [String] The subclass
    # @return [Boolean]
    def super_and_sub?(sup, sub)
      fqsup = qualify(sup)
      cls = qualify(sub)
      until fqsup.nil? || cls.nil?
        return true if cls == fqsup
        cls = qualify_superclass(cls)
      end
      false
    end

    private

    # @return [Array<String>]
    def workspace_filenames
      @workspace_filenames ||= []
    end

    # @return [YardMap]
    def yard_map
      @yard_map ||= YardMap.new
    end

    # A hash of source maps with filename keys.
    #
    # @return [Hash{String => SourceMap}]
    def source_map_hash
      @source_map_hash
    end

    # @return [ApiMap::Store]
    def store
      @store
    end

    # @return [Solargraph::ApiMap::Cache]
    def cache
      @cache
    end

    # @param fqns [String] A fully qualified namespace
    # @param scope [Symbol] :class or :instance
    # @param visibility [Array<Symbol>] :public, :protected, and/or :private
    # @param deep [Boolean]
    # @param skip [Set<String>]
    # @param no_core [Boolean] Skip core classes if true
    # @return [Array<Pin::Base>]
    def inner_get_methods fqns, scope, visibility, deep, skip, no_core = false
      return [] if no_core && fqns =~ /^(Object|BasicObject|Class|Module|Kernel)$/
      reqstr = "#{fqns}|#{scope}|#{visibility.sort}|#{deep}"
      return [] if skip.include?(reqstr)
      skip.add reqstr
      result = []
      if deep && scope == :instance
        store.get_prepends(fqns).reverse.each do |im|
          fqim = qualify(im, fqns)
          result.concat inner_get_methods(fqim, scope, visibility, deep, skip, true) unless fqim.nil?
        end
      end
      result.concat store.get_methods(fqns, scope: scope, visibility: visibility).sort{ |a, b| a.name <=> b.name }
      if deep
        if scope == :instance
          store.get_includes(fqns).reverse.each do |im|
            fqim = qualify(im, fqns)
            result.concat inner_get_methods(fqim, scope, visibility, deep, skip, true) unless fqim.nil?
          end
          fqsc = qualify_superclass(fqns)
          unless fqsc.nil?
            result.concat inner_get_methods(fqsc, scope, visibility, true, skip, no_core) unless fqsc.nil?
          end
        else
          store.get_extends(fqns).reverse.each do |em|
            fqem = qualify(em, fqns)
            result.concat inner_get_methods(fqem, :instance, visibility, deep, skip, true) unless fqem.nil?
          end
          fqsc = qualify_superclass(fqns)
          unless fqsc.nil?
            result.concat inner_get_methods(fqsc, scope, visibility, true, skip, true) unless fqsc.nil?
          end
          unless no_core || fqns.empty?
            type = get_namespace_type(fqns)
            result.concat inner_get_methods('Class', :instance, visibility, deep, skip, no_core) if type == :class
            result.concat inner_get_methods('Module', :instance, visibility, deep, skip, no_core)
          end
        end
        store.domains(fqns).each do |d|
          dt = ComplexType.try_parse(d)
          result.concat inner_get_methods(dt.namespace, dt.scope, [:public], deep, skip)
        end
      end
      result
    end

    # @param fqns [String]
    # @param visibility [Array<Symbol>]
    # @param skip [Set<String>]
    # @return [Array<Pin::Base>]
    def inner_get_constants fqns, visibility, skip
      return [] if fqns.nil? || skip.include?(fqns)
      skip.add fqns
      result = []
      store.get_prepends(fqns).each do |is|
        result.concat inner_get_constants(qualify(is, fqns), [:public], skip)
      end
      result.concat store.get_constants(fqns, visibility)
                    .sort { |a, b| a.name <=> b.name }
      store.get_includes(fqns).each do |is|
        result.concat inner_get_constants(qualify(is, fqns), [:public], skip)
      end
      fqsc = qualify_superclass(fqns)
      unless %w[Object BasicObject].include?(fqsc)
        result.concat inner_get_constants(fqsc, [:public], skip)
      end
      result
    end

    # @return [Hash]
    def path_macros
      @path_macros ||= {}
    end

    # @param namespace [String]
    # @param context [String]
    # @return [String]
    def qualify_lower namespace, context
      qualify namespace, context.split('::')[0..-2].join('::')
    end

    def qualify_superclass fqsub
      sup = store.get_superclass(fqsub)
      return nil if sup.nil?
      parts = fqsub.split('::')
      last = parts.pop
      parts.pop if last == sup
      qualify(sup, parts.join('::'))
    end

    # @param name [String]
    # @param root [String]
    # @param skip [Set<String>]
    # @return [String, nil]
    def inner_qualify name, root, skip
      return nil if name.nil?
      return nil if skip.include?(root)
      skip.add root
      possibles = []
      if name == ''
        if root == ''
          return ''
        else
          return inner_qualify(root, '', skip)
        end
      else
        return name if root == '' && store.namespace_exists?(name)
        roots = root.to_s.split('::')
        while roots.length > 0
          fqns = roots.join('::') + '::' + name
          return fqns if store.namespace_exists?(fqns)
          incs = store.get_includes(roots.join('::'))
          incs.each do |inc|
            foundinc = inner_qualify(name, inc, skip)
            possibles.push foundinc unless foundinc.nil?
          end
          roots.pop
        end
        if possibles.empty?
          incs = store.get_includes('')
          incs.each do |inc|
            foundinc = inner_qualify(name, inc, skip)
            possibles.push foundinc unless foundinc.nil?
          end
        end
        return name if store.namespace_exists?(name)
        return possibles.last
      end
    end

    # Get the namespace's type (Class or Module).
    #
    # @param fqns [String] A fully qualified namespace
    # @return [Symbol, nil] :class, :module, or nil
    def get_namespace_type fqns
      return nil if fqns.nil?
      # @type [Pin::Namespace, nil]
      pin = store.get_path_pins(fqns).select{|p| p.is_a?(Pin::Namespace)}.first
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

    # @param pins [Array<Pin::Base>]
    # @param visibility [Array<Symbol>]
    # @return [Array<Pin::Base>]
    def resolve_method_aliases pins, visibility = [:public, :private, :protected]
      result = []
      pins.each do |pin|
        resolved = resolve_method_alias(pin)
        next if resolved.respond_to?(:visibility) && !visibility.include?(resolved.visibility)
        result.push resolved
      end
      result
    end

    # @param pin [Pin::MethodAlias, Pin::Base]
    # @return [Pin::Method]
    def resolve_method_alias pin
      return pin if !pin.is_a?(Pin::MethodAlias) || @method_alias_stack.include?(pin.path)
      @method_alias_stack.push pin.path
      origin = get_method_stack(pin.full_context.namespace, pin.original, scope: pin.scope).first
      @method_alias_stack.pop
      return pin if origin.nil?
      # @todo Clean this up
      args = {
        location: pin.location,
        closure: pin.closure,
        name: pin.name,
        comments: origin.comments,
        scope: origin.scope,
        visibility: origin.visibility,
        parameters: origin.parameters,
        attribute: origin.attribute?
      }
      Pin::Method.new **args
    end
  end
end
