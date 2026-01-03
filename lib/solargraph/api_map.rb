# frozen_string_literal: true

require 'pathname'
require 'yard'
require 'solargraph/yard_tags'

module Solargraph
  # An aggregate provider for information about Workspaces, Sources, gems, and
  # the Ruby core.
  #
  class ApiMap
    autoload :Cache,          'solargraph/api_map/cache'
    autoload :SourceToYard,   'solargraph/api_map/source_to_yard'
    autoload :Store,          'solargraph/api_map/store'
    autoload :Index,          'solargraph/api_map/index'
    autoload :Constants,      'solargraph/api_map/constants'

    # @return [Array<String>]
    attr_reader :unresolved_requires

    @@core_map = RbsMap::CoreMap.new

    # @return [Array<String>]
    attr_reader :missing_docs

    # @param pins [Array<Solargraph::Pin::Base>]
    # @param loose_unions [Boolean] if true, a potential type can be
    #   inferred if ANY of the UniqueTypes in the base chain's
    #   ComplexType match it. If false, every single UniqueTypes in
    #   the base must be ALL able to independently provide this
    #   type.  The former is useful during completion, but the
    #   latter is best for typechecking at higher levels.
    #
    def initialize pins: [], loose_unions: true
      @source_map_hash = {}
      @cache = Cache.new
      @loose_unions = loose_unions
      index pins
    end

    #
    # This is a mutable object, which is cached in the Chain class -
    # if you add any fields which change the results of calls (not
    # just caches), please also change `equality_fields` below.
    #

    # @param other [Object]
    def eql?(other)
      self.class == other.class &&
        # @sg-ignore Flow sensitive typing needs to handle self.class == other.class
        equality_fields == other.equality_fields
    end

    # @param other [Object]
    def ==(other)
      self.eql?(other)
    end

    def hash
      equality_fields.hash
    end

    attr_reader :loose_unions

    def to_s
      self.class.to_s
    end

    # avoid enormous dump
    def inspect
      to_s
    end

    # @param pins [Array<Pin::Base>]
    # @return [self]
    def index pins
      # @todo This implementation is incomplete. It should probably create a
      #   Bench.
      @source_map_hash = {}
      conventions_environ.clear
      cache.clear
      store.update @@core_map.pins, pins
      self
    end

    # Map a single source.
    #
    # @param source [Source]
    # @param live [Boolean] True for live source map (active editor file)
    # @return [self]
    def map source, live: false
      map = Solargraph::SourceMap.map(source)
      catalog Bench.new(source_maps: [map], live_map: live ? map : nil)
      self
    end

    # Catalog a bench.
    #
    # @param bench [Bench]
    # @return [self]
    def catalog bench
      @source_map_hash = bench.source_map_hash
      iced_pins = bench.icebox.flat_map(&:pins)
      live_pins = bench.live_map&.all_pins || []
      conventions_environ.clear
      source_map_hash.each_value do |map|
        conventions_environ.merge map.conventions_environ
      end
      unresolved_requires = (bench.external_requires + conventions_environ.requires + bench.workspace.config.required).to_a.compact.uniq
      recreate_docmap = @unresolved_requires != unresolved_requires ||
                     @doc_map&.uncached_yard_gemspecs&.any? ||
                     @doc_map&.uncached_rbs_collection_gemspecs&.any? ||
                     @doc_map&.rbs_collection_path != bench.workspace.rbs_collection_path
      if recreate_docmap
        @doc_map = DocMap.new(unresolved_requires, [], bench.workspace) # @todo Implement gem preferences
        @unresolved_requires = @doc_map.unresolved_requires
      end
      @cache.clear if store.update(@@core_map.pins, @doc_map.pins, conventions_environ.pins, iced_pins, live_pins)
      @missing_docs = [] # @todo Implement missing docs
      self
    end

    # @todo need to model type def statement in chains as a symbol so
    #   that this overload of 'protected' will typecheck @sg-ignore
    # @sg-ignore
    protected def equality_fields
      [self.class, @source_map_hash, conventions_environ, @doc_map, @unresolved_requires, @missing_docs, @loose_unions]
    end

    # @return [DocMap]
    def doc_map
      @doc_map ||= DocMap.new([], [])
    end

    # @return [::Array<Gem::Specification>]
    def uncached_gemspecs
      @doc_map&.uncached_gemspecs || []
    end

    # @return [::Array<Gem::Specification>]
    def uncached_rbs_collection_gemspecs
      @doc_map.uncached_rbs_collection_gemspecs
    end

    # @return [::Array<Gem::Specification>]
    def uncached_yard_gemspecs
      @doc_map.uncached_yard_gemspecs
    end

    # @return [Enumerable<Pin::Base>]
    def core_pins
      @@core_map.pins
    end

    # @param name [String, nil]
    # @return [YARD::Tags::MacroDirective, nil]
    def named_macro name
      # @sg-ignore Need to add nil check here
      store.named_macros[name]
    end

    # @return [Set<String>]
    def required
      @required ||= Set.new
    end

    # @return [Environ]
    def conventions_environ
      @conventions_environ ||= Environ.new
    end

    # @param filename [String]
    # @param position [Position, Array(Integer, Integer)]
    # @return [Source::Cursor]
    def cursor_at filename, position
      position = Position.normalize(position)
      raise FileNotFoundError, "File not found: #{filename}" unless source_map_hash.key?(filename)
      source_map_hash[filename].cursor_at(position)
    end

    # Get a clip by filename and position.
    #
    # @param filename [String]
    # @param position [Position, Array(Integer, Integer)]
    # @return [SourceMap::Clip]
    def clip_at filename, position
      position = Position.normalize(position)
      clip(cursor_at(filename, position))
    end

    # Create an ApiMap with a workspace in the specified directory.
    #
    # @param directory [String]
    # @param loose_unions [Boolean] See #initialize
    #
    # @return [ApiMap]
    def self.load directory, loose_unions: true
      api_map = new(loose_unions: loose_unions)
      workspace = Solargraph::Workspace.new(directory)
      # api_map.catalog Bench.new(workspace: workspace)
      library = Library.new(workspace)
      library.map!
      api_map.catalog library.bench
      api_map
    end

    # @param out [StringIO, IO, nil]
    # @return [void]
    def cache_all!(out)
      @doc_map.cache_all!(out)
    end

    # @param gemspec [Gem::Specification]
    # @param rebuild [Boolean]
    # @param out [StringIO, IO, nil]
    # @return [void]
    def cache_gem(gemspec, rebuild: false, out: nil)
      @doc_map.cache(gemspec, rebuild: rebuild, out: out)
    end

    class << self
      include Logging
    end

    # Create an ApiMap with a workspace in the specified directory and cache
    # any missing gems.
    #
    #
    # @param directory [String]
    # @param out [IO, StringIO, nil] The output stream for messages
    # @param loose_unions [Boolean] See #initialize
    #
    # @return [ApiMap]
    def self.load_with_cache directory, out = $stdout, loose_unions: true
      api_map = load(directory, loose_unions: loose_unions)
      if api_map.uncached_gemspecs.empty?
        logger.info { "All gems cached for #{directory}" }
        return api_map
      end

      api_map.cache_all!(out)
      load(directory, loose_unions: loose_unions)
    end

    # @return [Array<Solargraph::Pin::Base>]
    def pins
      store.pins.clone.freeze
    end

    # An array of pins based on Ruby keywords (`if`, `end`, etc.).
    #
    # @return [Enumerable<Solargraph::Pin::Keyword>]
    def keyword_pins
      store.pins_by_class(Pin::Keyword)
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
    # @return [Array<Solargraph::Pin::Constant, Solargraph::Pin::Namespace>]
    def get_constants namespace, *contexts
      namespace ||= ''
      gates = contexts.clone
      gates.push '' if contexts.empty? && namespace.empty?
      gates.push namespace unless namespace.empty?
      store.constants
           .collect(gates)
           .select { |pin| namespace.empty? || contexts.empty? || pin.namespace == namespace }
           .select { |pin| pin.visibility == :public || pin.namespace == namespace }
    end

    # @param namespace [String]
    # @param context [String]
    # @return [Array<Pin::Namespace>]
    def get_namespace_pins namespace, context
      store.fqns_pins(qualify(namespace, context))
    end

    # Determine fully qualified tag for a given tag used inside the
    # definition of another tag ("context"). This method will start
    # the search in the specified context until it finds a match for
    # the tag.
    #
    # Does not recurse into qualifying the type parameters, but
    # returns any which were passed in unchanged.
    #
    # @param tag [String, nil] The namespace to
    #   match, complete with generic parameters set to appropriate
    #   values if available
    # @param gates [Array<String>] The fully qualified context in which
    #   the tag was referenced; start from here to resolve the name.
    #   Should not be prefixed with '::'.
    # @return [String, nil] fully qualified tag
    def qualify tag, *gates
      store.constants.qualify(tag, *gates)
    end

    # @see Store::Constants#resolve
    #
    # @param name [String]
    # @param gates [Array<String, Array<String>>]
    # @return [String, nil]
    def resolve name, *gates
      store.constants.resolve(name, *gates)
    end

    # Get a fully qualified namespace from a reference pin.
    #
    # @param pin [Pin::Reference]
    # @return [String, nil]
    def dereference(pin)
      store.constants.dereference(pin)
    end

    # @param fqns [String]
    # @return [Array<Pin::Reference::Extend>]
    def get_extends(fqns)
      store.get_extends(fqns)
    end

    # @param fqns [String]
    # @return [Array<Pin::Reference::Include>]
    def get_includes(fqns)
      store.get_includes(fqns)
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
      sc_fqns = namespace
      while (sc = store.get_superclass(sc_fqns))
        # @sg-ignore flow sensitive typing needs to handle "if foo = bar"
        sc_fqns = store.constants.dereference(sc)
        result.concat store.get_instance_variables(sc_fqns, scope)
      end
      result
    end

    # Find a variable pin by name and where it is used.
    #
    # Resolves our most specific view of this variable's type by
    # preferring pins created by flow-sensitive typing when we have
    # them based on the Closure and Location.
    #
    # @param candidates [Array<Pin::BaseVariable>]
    # @param name [String]
    # @param closure [Pin::Closure]
    # @param location [Location]
    #
    # @return [Pin::BaseVariable, nil]
    def var_at_location(candidates, name, closure, location)
      with_correct_name = candidates.select { |pin| pin.name == name}
      vars_at_location = with_correct_name.reject do |pin|
        # visible_at? excludes the starting position, but we want to
        # include it for this purpose
        (!pin.visible_at?(closure, location) && !pin.starts_at?(location))
      end

      vars_at_location.inject(&:combine_with)
    end

    # Get an array of class variable pins for a namespace.
    #
    # @param namespace [String] A fully qualified namespace
    # @return [Enumerable<Solargraph::Pin::ClassVariable>]
    def get_class_variable_pins(namespace)
      prefer_non_nil_variables(store.get_class_variables(namespace))
    end

    # @return [Enumerable<Solargraph::Pin::Base>]
    def get_symbols
      store.get_symbols
    end

    # @return [Enumerable<Solargraph::Pin::GlobalVariable>]
    def get_global_variable_pins
      store.pins_by_class(Pin::GlobalVariable)
    end

    # @return [Enumerable<Solargraph::Pin::Block>]
    def get_block_pins
      store.pins_by_class(Pin::Block)
    end

    # Get an array of methods available in a particular context.
    #
    # @param rooted_tag [String] The fully qualified namespace to search for methods
    # @param scope [Symbol] :class or :instance
    # @param visibility [Array<Symbol>] :public, :protected, and/or :private
    # @param deep [Boolean] True to include superclasses, mixins, etc.
    # @return [Array<Solargraph::Pin::Method>]
    def get_methods rooted_tag, scope: :instance, visibility: [:public], deep: true
      if rooted_tag.start_with? 'Array('
        # Array() are really tuples - use our fill, as the RBS repo
        # does not give us definitions for it
        rooted_tag = "Solargraph::Fills::Tuple(#{rooted_tag[6..-2]})"
      end
      rooted_type = ComplexType.try_parse(rooted_tag)
      fqns = rooted_type.namespace
      namespace_pin = store.get_path_pins(fqns).select { |p| p.is_a?(Pin::Namespace) }.first
      cached = cache.get_methods(rooted_tag, scope, visibility, deep)
      return cached.clone unless cached.nil?
      # @type [Array<Solargraph::Pin::Method>]
      result = []
      skip = Set.new
      if rooted_tag == ''
        # @todo Implement domains
        conventions_environ.domains.each do |domain|
          type = ComplexType.try_parse(domain)
          next if type.undefined?
          result.concat inner_get_methods(type.name, type.scope, visibility, deep, skip)
        end
        result.concat inner_get_methods(rooted_tag, :class, visibility, deep, skip)
        result.concat inner_get_methods(rooted_tag, :instance, visibility, deep, skip)
        result.concat inner_get_methods('Kernel', :instance, visibility, deep, skip)
      else
        result.concat inner_get_methods(rooted_tag, scope, visibility, deep, skip)
        unless %w[Class Class<Class>].include?(rooted_tag)
          result.map! do |pin|
            next pin unless pin.path == 'Class#new'
            init_pin = get_method_stack(rooted_tag, 'initialize').first
            next pin unless init_pin

            type = ComplexType::SELF
            new_pin = Pin::Method.new(
              name: 'new',
              scope: :class,
              location: init_pin.location,
              return_type: type,
              comments: init_pin.comments,
              closure: init_pin.closure,
              source: init_pin.source,
              type_location: init_pin.type_location,
            )
            new_pin.parameters = init_pin.parameters.map do |init_param|
              param = init_param.clone
              param.closure = new_pin
              param.reset_generated!
              param
            end.freeze
            new_pin.signatures = init_pin.signatures.map do |init_sig|
              sig = init_sig.proxy(type)
              sig.parameters = init_sig.parameters.map do |param|
                param = param.clone
                param.closure = new_pin
                param.reset_generated!
                param
              end.freeze
              sig.closure = new_pin
              sig.reset_generated!
              sig
            end.freeze
            new_pin
          end
        end
        result.concat inner_get_methods('Kernel', :instance, [:public], deep, skip) if visibility.include?(:private)
        result.concat inner_get_methods('Module', scope, visibility, deep, skip) if scope == :module
      end
      result = resolve_method_aliases(result, visibility)
      if namespace_pin && rooted_tag != rooted_type.name
        result = result.map { |method_pin| method_pin.resolve_generics(namespace_pin, rooted_type) }
      end
      cache.set_methods(rooted_tag, scope, visibility, deep, result)
      result
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
    # @param complex_type [Solargraph::ComplexType] The complex type of the namespace
    # @param context [String] The context from which the type is referenced
    # @param internal [Boolean] True to include private methods
    # @return [Array<Solargraph::Pin::Base>]
    def get_complex_type_methods complex_type, context = '', internal = false
      # This method does not qualify the complex type's namespace because
      # it can cause conflicts between similar names, e.g., `Foo` vs.
      # `Other::Foo`. It still takes a context argument to determine whether
      # protected and private methods are visible.
      return [] if complex_type.undefined? || complex_type.void?
      result = Set.new
      complex_type.each do |type|
        if type.duck_type?
          result.add Pin::DuckMethod.new(name: type.to_s[1..-1], source: :api_map)
          result.merge get_methods('Object')
        else
          unless type.nil? || type.name == 'void'
            visibility = [:public]
            if type.namespace == context || super_and_sub?(type.namespace, context)
              visibility.push :protected
              visibility.push :private if internal
            end
            result.merge get_methods(type.tag, scope: type.scope, visibility: visibility)
          end
        end
      end
      result.to_a
    end

    # Get a stack of method pins for a method name in a potentially
    # parameterized namespace. The order of the pins corresponds to
    # the ancestry chain, with highest precedence first.
    #
    # @example
    #   api_map.get_method_stack('Subclass', 'method_name')
    #     #=> [ <Subclass#method_name pin>, <Superclass#method_name pin> ]
    #
    # @param rooted_tag [String] Parameterized namespace, fully qualified
    # @param name [String] Method name to look up
    # @param scope [Symbol] :instance or :class
    # @param visibility [Array<Symbol>] :public, :protected, and/or :private
    # @param preserve_generics [Boolean] True to preserve any
    #   unresolved generic parameters, false to erase them
    # @return [Array<Solargraph::Pin::Method>]
    def get_method_stack rooted_tag, name, scope: :instance, visibility: [:private, :protected, :public], preserve_generics: false
      rooted_type = ComplexType.parse(rooted_tag)
      fqns = rooted_type.namespace
      namespace_pin = store.get_path_pins(fqns).first
      methods = if namespace_pin.is_a?(Pin::Constant)
                  type = namespace_pin.infer(self)
                  if type.defined?
                    namespace_pin = store.get_path_pins(type.namespace).first
                    get_methods(type.namespace, scope: scope, visibility: visibility).select { |p| p.name == name }
                  else
                    []
                  end
                else
                  get_methods(rooted_tag, scope: scope, visibility: visibility).select { |p| p.name == name }
                end
      methods = erase_generics(namespace_pin, rooted_type, methods) unless preserve_generics
      methods
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
      pins.map(&:path)
          .compact
          .select { |path| path.downcase.include?(query.downcase) }
    end

    # @deprecated This method is likely superfluous. Calling #get_path_pins
    #   directly should be sufficient.
    #
    # @param path [String] The path to find
    # @return [Enumerable<Pin::Base>]
    def document path
      get_path_pins(path)
    end

    # Get an array of all symbols in the workspace that match the query.
    #
    # @param query [String]
    # @return [Array<Pin::Base>]
    def query_symbols query
      Pin::Search.new(
        source_map_hash.values.flat_map(&:document_symbols),
        query
      ).results
    end

    # @param location [Solargraph::Location]
    # @return [Array<Solargraph::Pin::Base>]
    def locate_pins location
      return [] if location.nil? || !source_map_hash.key?(location.filename)
      resolve_method_aliases source_map_hash[location.filename].locate_pins(location)
    end

    # @raise [FileNotFoundError] if the cursor's file is not in the ApiMap
    # @param cursor [Source::Cursor]
    # @return [SourceMap::Clip]
    def clip cursor
      # @sg-ignore Need to add nil check here
      raise FileNotFoundError, "ApiMap did not catalog #{cursor.filename}" unless source_map_hash.key?(cursor.filename)

      SourceMap::Clip.new(self, cursor)
    end

    # Get an array of document symbols from a file.
    #
    # @param filename [String]
    # @return [Array<Pin::Symbol>]
    def document_symbols filename
      return [] unless source_map_hash.key?(filename) # @todo Raise error?
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
      raise FileNotFoundError, "Source map for `#{filename}` not found" unless source_map_hash.key?(filename)
      source_map_hash[filename]
    end

    # True if the specified file was included in a bundle, i.e., it's either
    # included in a workspace or open in a library.
    #
    # @param filename [String]
    def bundled? filename
      source_map_hash.keys.include?(filename)
    end

    # Check if a class is a superclass of another class.
    #
    # @param sup [String] The superclass
    # @param sub [String] The subclass
    # @return [Boolean]
    def super_and_sub?(sup, sub)
      sup = ComplexType.try_parse(sup)
      sub = ComplexType.try_parse(sub)
      # @todo If two literals are different values of the same type, it would
      #   make more sense for super_and_sub? to return true, but there are a
      #   few callers that currently expect this to be false.
      # @sg-ignore We should understand reassignment of variable to new type
      return false if sup.literal? && sub.literal? && sup.to_s != sub.to_s
      # @sg-ignore We should understand reassignment of variable to new type
      sup = sup.simplify_literals.to_s
      # @sg-ignore We should understand reassignment of variable to new type
      sub = sub.simplify_literals.to_s
      return true if sup == sub
      sc_fqns = sub
      while (sc = store.get_superclass(sc_fqns))
        # @sg-ignore flow sensitive typing needs to handle "if foo = bar"
        sc_new = store.constants.dereference(sc)
        # Cyclical inheritance is invalid
        return false if sc_new == sc_fqns
        sc_fqns = sc_new
        return true if sc_fqns == sup
      end
      false
    end

    # Check if the host class includes the specified module, ignoring
    # type parameters used.
    #
    # @param host_ns [String] The class namesapce (no type parameters)
    # @param module_ns [String] The module namespace (no type parameters)
    #
    # @return [Boolean]
    def type_include?(host_ns, module_ns)
      store.get_includes(host_ns).map { |inc_tag| inc_tag.type.name }.include?(module_ns)
    end

    # @param pins [Enumerable<Pin::Base>]
    # @param visibility [Enumerable<Symbol>]
    # @return [Array<Pin::Base>]
    def resolve_method_aliases pins, visibility = [:public, :private, :protected]
      with_resolved_aliases = pins.map do |pin|
        next pin unless pin.is_a?(Pin::MethodAlias)
        resolved = resolve_method_alias(pin)
        # @sg-ignore Need to add nil check here
        next nil if resolved.respond_to?(:visibility) && !visibility.include?(resolved.visibility)
        resolved
      end.compact
      logger.debug { "ApiMap#resolve_method_aliases(pins=#{pins.map(&:name)}, visibility=#{visibility}) => #{with_resolved_aliases.map(&:name)}" }
      GemPins.combine_method_pins_by_path(with_resolved_aliases)
    end

    # @param fq_reference_tag [String] A fully qualified whose method should be pulled in
    # @param namespace_pin [Pin::Base] Namespace pin for the rooted_type
    #   parameter - used to pull generics information
    # @param type [ComplexType] The type which is having its
    #   methods supplemented from fq_reference_tag
    # @param scope [Symbol] :class or :instance
    # @param visibility [Array<Symbol>] :public, :protected, and/or :private
    # @param deep [Boolean]
    # @param skip [Set<String>]
    # @param no_core [Boolean] Skip core classes if true
    # @return [Array<Pin::Base>]
    def inner_get_methods_from_reference(fq_reference_tag, namespace_pin, type, scope, visibility, deep, skip, no_core)
      logger.debug { "ApiMap#add_methods_from_reference(type=#{type}) starting" }

      # Ensure the types returned by the methods in the referenced
      # type are relative to the generic values passed in the
      # reference.  e.g., Foo<String> might include Enumerable<String>
      #
      # @todo perform the same translation in the other areas
      #  here after adding a spec and handling things correctly
      #  in ApiMap::Store and RbsMap::Conversions for each
      resolved_reference_type = ComplexType.parse(fq_reference_tag).force_rooted.resolve_generics(namespace_pin, type)
      # @todo Can inner_get_methods be cached?  Lots of lookups of base types going on.
      methods = inner_get_methods(resolved_reference_type.tag, scope, visibility, deep, skip, no_core)
      if namespace_pin && !resolved_reference_type.all_params.empty?
        reference_pin = store.get_path_pins(resolved_reference_type.name).select { |p| p.is_a?(Pin::Namespace) }.first
        # logger.debug { "ApiMap#add_methods_from_reference(type=#{type}) - resolving generics with #{reference_pin.generics}, #{resolved_reference_type.rooted_tags}" }
        methods = methods.map do |method_pin|
          method_pin.resolve_generics(reference_pin, resolved_reference_type)
        end
      end
      # logger.debug { "ApiMap#add_methods_from_reference(type=#{type}) - resolved_reference_type: #{resolved_reference_type} for type=#{type}: #{methods.map(&:name)}" }
      methods
    end

    private

    # A hash of source maps with filename keys.
    #
    # @return [Hash{String => SourceMap}]
    attr_reader :source_map_hash

    # @return [ApiMap::Store]
    def store
      @store ||= Store.new
    end

    # @return [Solargraph::ApiMap::Cache]
    attr_reader :cache

    # @param rooted_tag [String] A fully qualified namespace, with
    #   generic parameter values if applicable
    # @param scope [Symbol] :class or :instance
    # @param visibility [Array<Symbol>] :public, :protected, and/or :private
    # @param deep [Boolean]
    # @param skip [Set<String>]
    # @param no_core [Boolean] Skip core classes if true
    # @return [Array<Pin::Base>]
    def inner_get_methods rooted_tag, scope, visibility, deep, skip, no_core = false
      rooted_type = ComplexType.parse(rooted_tag).force_rooted
      fqns = rooted_type.namespace
      fqns_generic_params = rooted_type.all_params
      namespace_pin = store.get_path_pins(fqns).select { |p| p.is_a?(Pin::Namespace) }.first
      return [] if no_core && fqns =~ /^(Object|BasicObject|Class|Module)$/
      reqstr = "#{fqns}|#{scope}|#{visibility.sort}|#{deep}"
      return [] if skip.include?(reqstr)
      skip.add reqstr
      result = []
      environ = Convention.for_object(self, rooted_tag, scope, visibility, deep, skip, no_core)
      # ensure we start out with any immediate methods in this
      # namespace so we roughly match the same ordering of get_methods
      # and obey the 'deep' instruction
      direct_convention_methods, convention_methods_by_reference = environ.pins.partition { |p| p.namespace == rooted_tag }
      result.concat direct_convention_methods

      if deep && scope == :instance
        store.get_prepends(fqns).reverse.each do |im|
          fqim = store.constants.dereference(im)
          result.concat inner_get_methods(fqim, scope, visibility, deep, skip, true) unless fqim.nil?
        end
      end
      # Store#get_methods doesn't know about full tags, just
      # namespaces; resolving the generics in the method pins is this
      # class' responsibility
      methods = store.get_methods(fqns, scope: scope, visibility: visibility).sort{ |a, b| a.name <=> b.name }
      logger.info { "ApiMap#inner_get_methods(rooted_tag=#{rooted_tag.inspect}, scope=#{scope.inspect}, visibility=#{visibility.inspect}, deep=#{deep.inspect}, skip=#{skip.inspect}, fqns=#{fqns}) - added from store: #{methods}" }
      result.concat methods
      if deep
        result.concat convention_methods_by_reference

        if scope == :instance
          store.get_includes(fqns).reverse.each do |ref|
            in_tag = dereference(ref)
            # @sg-ignore Need to add nil check here
            result.concat inner_get_methods_from_reference(in_tag, namespace_pin, rooted_type, scope, visibility, deep, skip, true)
          end
          rooted_sc_tag = qualify_superclass(rooted_tag)
          unless rooted_sc_tag.nil?
            result.concat inner_get_methods_from_reference(rooted_sc_tag, namespace_pin, rooted_type, scope, visibility, true, skip, no_core)
          end
        else
          logger.info { "ApiMap#inner_get_methods(#{fqns}, #{scope}, #{visibility}, #{deep}, #{skip}) - looking for get_extends() from #{fqns}" }
          store.get_extends(fqns).reverse.each do |em|
            fqem = dereference(em)
            result.concat inner_get_methods(fqem, :instance, visibility, deep, skip, true) unless fqem.nil?
          end
          rooted_sc_tag = qualify_superclass(rooted_tag)
          unless rooted_sc_tag.nil?
            result.concat inner_get_methods_from_reference(rooted_sc_tag, namespace_pin, rooted_type, scope, visibility, true, skip, true)
          end
          unless no_core || fqns.empty?
            type = get_namespace_type(fqns)
            result.concat inner_get_methods('Class', :instance, visibility, deep, skip, no_core) if type == :class
            result.concat inner_get_methods('Module', :instance, visibility, deep, skip, no_core)
          end
        end
        store.domains(fqns).each do |d|
          dt = ComplexType.try_parse(d)
          result.concat inner_get_methods(dt.namespace, dt.scope, visibility, deep, skip)
        end
      end
      result
    end

    # @return [Hash]
    def path_macros
      @path_macros ||= {}
    end

    # @param fq_sub_tag [String]
    # @return [String, nil]
    def qualify_superclass fq_sub_tag
      store.qualify_superclass fq_sub_tag
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
    # @param pins [Enumerable<Pin::BaseVariable>]
    # @return [Enumerable<Pin::BaseVariable>]
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

    include Logging

    private

    # @param alias_pin [Pin::MethodAlias]
    # @return [Pin::Method, nil]
    def resolve_method_alias(alias_pin)
      ancestors = store.get_ancestors(alias_pin.full_context.reduce_class_type.tag)
      # @type [Pin::Method, nil]
      original = nil

      # Search each ancestor for the original method
      ancestors.each do |ancestor_fqns|
        next if ancestor_fqns.nil?
        ancestor_method_path = "#{ancestor_fqns}#{alias_pin.scope == :instance ? '#' : '.'}#{alias_pin.original}"

        # Search for the original method in the ancestor
        original = store.get_path_pins(ancestor_method_path).find do |candidate_pin|
          next if candidate_pin == alias_pin

          if candidate_pin.is_a?(Pin::MethodAlias)
            # recursively resolve method aliases
            resolved = resolve_method_alias(candidate_pin)
            break resolved if resolved
          end

          candidate_pin.is_a?(Pin::Method) && candidate_pin.scope == alias_pin.scope
        end

        break if original
      end

      create_resolved_alias_pin(alias_pin, original) if original
    end

    # Fast path for creating resolved alias pins without individual method stack lookups
    # @param alias_pin [Pin::MethodAlias] The alias pin to resolve
    # @param original [Pin::Method] The original method pin that was already found
    # @return [Pin::Method] The resolved method pin
    def create_resolved_alias_pin(alias_pin, original)
      # Build the resolved method pin directly (same logic as resolve_method_alias but without lookup)
      args = {
        location: alias_pin.location,
        type_location: original.type_location,
        closure: alias_pin.closure,
        name: alias_pin.name,
        comments: original.comments,
        scope: original.scope,
        visibility: original.visibility,
        signatures: original.signatures.map(&:clone).freeze,
        attribute: original.attribute?,
        generics: original.generics.clone,
        return_type: original.return_type,
        source: :resolve_method_alias
      }
      resolved_pin = Pin::Method.new **args

      # Clone signatures and parameters
      resolved_pin.signatures.each do |sig|
        sig.parameters = sig.parameters.map(&:clone).freeze
        sig.source = :resolve_method_alias
        sig.parameters.each do |param|
          param.closure = resolved_pin
          param.source = :resolve_method_alias
          param.reset_generated!
        end
        sig.closure = resolved_pin
        sig.reset_generated!
      end

      resolved_pin
    end

    # @param namespace_pin [Pin::Namespace]
    # @param rooted_type [ComplexType]
    # @param pins [Enumerable<Pin::Base>]
    # @return [Array<Pin::Base>]
    def erase_generics(namespace_pin, rooted_type, pins)
      return pins unless should_erase_generics_when_done?(namespace_pin, rooted_type)

      logger.debug("Erasing generics on namespace_pin=#{namespace_pin} / rooted_type=#{rooted_type}")
      pins.map do |method_pin|
        method_pin.erase_generics(namespace_pin.generics)
      end
    end

    # @param namespace_pin [Pin::Namespace]
    # @param rooted_type [ComplexType]
    def should_erase_generics_when_done?(namespace_pin, rooted_type)
      has_generics?(namespace_pin) && !can_resolve_generics?(namespace_pin, rooted_type)
    end

    # @param namespace_pin [Pin::Namespace, Pin::Constant]
    def has_generics?(namespace_pin)
      namespace_pin.is_a?(Pin::Namespace) && !namespace_pin.generics.empty?
    end

    # @param namespace_pin [Pin::Namespace]
    # @param rooted_type [ComplexType]
    def can_resolve_generics?(namespace_pin, rooted_type)
      has_generics?(namespace_pin) && !rooted_type.all_params.empty?
    end
  end
end
