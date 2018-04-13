require 'rubygems'
require 'set'
require 'time'

module Solargraph
  class ApiMap
    autoload :Cache,        'solargraph/api_map/cache'
    autoload :SourceToYard, 'solargraph/api_map/source_to_yard'
    autoload :Completion,   'solargraph/api_map/completion'

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
    # @param source [Solargraph::Source]
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
      else
        current_workspace_sources.reject{|s| workspace.sources.include?(s)}.each do |source|
          eliminate source
        end
        @sources = workspace.sources
        @sources.push @virtual_source unless @virtual_source.nil?
        cache.clear
        namespace_map.clear
        @sources.each do |s|
          s.namespaces.each do |n|
            namespace_map[n] ||= []
            namespace_map[n].concat s.namespace_pins(n)
          end
        end
        @sources.each do |source|
          if @stime.nil? or source.stime > @stime
            eliminate source
            map_source source
          end
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

    # Get suggestions for constants in the specified namespace. The result
    # may contain both constant and namespace pins.
    #
    # @param fqns [String] The fully qualified namespace
    # @param visibility [Array<Symbol>] :public and/or :private
    # @return [Array<Solargraph::Pin::Base>]
    def get_constants namespace, context = ''
      namespace ||= ''
      skip = []
      result = []
      bases = context.split('::')
      while bases.length > 0
        built = bases.join('::')
        fqns = find_fully_qualified_namespace(namespace, built)
        visibility = [:public]
        visibility.push :private if fqns == context
        result.concat inner_get_constants(fqns, visibility, skip)
        bases.pop
      end
      fqns = find_fully_qualified_namespace(namespace, '')
      visibility = [:public]
      visibility.push :private if fqns == context
      result.concat inner_get_constants(fqns, visibility, skip)
      result
    end

    # Get a fully qualified namespace name. This method will start the search
    # in the specified root until it finds a match for the name.
    #
    # @param name [String] The namespace to match
    # @param root [String] The context to search
    # @return [String]
    def find_fully_qualified_namespace name, root = '', skip = []
      return name if name == root
      # refresh
      return nil if name.nil?
      return nil if skip.include?(root)
      skip.push root
      if name == ''
        if root == ''
          return ''
        # else
        #   return find_fully_qualified_namespace(root, '', skip)
        end
      else
        if (root == '')
          return name unless namespace_map[name].nil?
          im = @namespace_includes['']
          unless im.nil?
            im.each do |i|
              i.resolve self
              return i.name unless i.name.nil?
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
              i.resolve self
              return i.name unless i.name.nil?
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
      raw = @ivar_pins[namespace]
      return [] if raw.nil?
      # @todo This is a crazy workaround because instance variables in the
      #   global namespace might be in either scope
      pins = prefer_non_nil_variables(raw)
      return pins if namespace.empty?
      pins.select{ |pin| pin.scope == scope }
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
      # refresh
      @symbol_pins
    end

    # This method checks the signature from the namespace's internal context,
    # i.e., the first word in the signature can be a private or protected
    # method, a private constant, an instance variable, or a class variable.
    # Local variables are not accessible.
    #
    # @return [String]
    def infer_type signature, namespace = '', scope: :instance
      context = combine_type(namespace, scope)
      parts = signature.split('.')
      base = parts.shift
      return nil if base.nil?
      type = infer_word_type(base, context, true)
      return nil if type.nil?
      until parts.empty?
        word = parts.shift
        type = infer_method_type(word, type)
        return nil if type.nil?
      end
      type
    end

    # @return [Solargraph::Pin::Base]
    def tail_pins signature, fqns, scope, visibility
      return [] if signature.nil?
      type = combine_type(fqns, scope)
      return infer_word_pins(signature, type, true) unless signature.include?('.')
      parts = signature.split('.')
      last = parts.pop
      base = parts.join('.')
      type = infer_type(base, fqns, scope: scope)
      return [] if type.nil?
      infer_word_pins(last, type, true)
    end

    # @return [Solargraph::Pin::Base]
    def tail_pin signature, fqns, scope, visibility
      tail_pins(signature, fqns, scope, visibility).first
    end

    # Get an array of pins for a word in the provided context. A word can be
    # a constant, a global variable, or a method name. Private and protected
    # words are excluded by default. Set the `internal` parameter to `true` to
    # to include private and protected methods, private constants, instance
    # variables, and class variables.
    #
    # @param word [String]
    # @param base_type [String]
    # @param internal [Boolean]
    # @return [Array<Solargraph::Pin::Base>]
    def infer_word_pins word, base_type, internal = false
      pins = []
      namespace, scope = extract_namespace_and_scope(base_type)
      if word == 'self' and internal
        context = (internal ? namespace.split('::')[0..-2].join(';;') : '')
        fqns = find_fully_qualified_namespace(namespace, context)
        pins.concat get_path_suggestions(fqns) unless fqns.nil?
        return pins
      end
      fqns = find_fully_qualified_namespace(word, namespace)
      unless fqns.nil?
        pins.concat get_path_suggestions(fqns) unless fqns.nil?
        return pins
      end
      if internal
        if word.start_with?('@@')
          pins.concat get_class_variable_pins(namespace).select{|pin| pin.name == word}
          return pins
        elsif word.start_with?('@')
          pins.concat get_instance_variable_pins(namespace, scope).select{|pin| pin.name == word}
          return pins
        end
      end
      if word.start_with?('$')
        pins.concat get_global_variable_pins.select{|pin| pin.name == word}
        return pins
      end
      pins.concat get_constants(namespace, (internal ? namespace : '')).select{|pin| pin.name == word}
      if pins.empty?
        pins.concat get_type_methods(base_type, (internal ? base_type : '')).select{|pin| pin.name == word}
        pins.concat get_type_methods('Kernel').select{|pin| pin.name == word}
      end
      pins
    end

    # @return [Solargraph::Pin::Base]
    def infer_word_pin word, base_type, internal = false
      infer_word_pins(word, base_type, internal).first
    end

    # @return [String]
    def infer_word_type word, base_type, internal = false
      return base_type if word == 'self' and internal
      if word == 'new'
        namespace, scope = extract_namespace_and_scope(base_type)
        return namespace if scope == :class
      end
      pin = infer_word_pin(word, base_type, internal)
      return nil if pin.nil?
      pin.resolve self
      return pin.return_type unless pin.return_type.nil?
      return nil unless pin.variable?
      return nil if pin.signature.nil?
      return nil if pin.signature.split('.').first == word
      ns, sc = extract_namespace_and_scope(base_type)
      infer_type pin.signature, ns, scope: sc
    end

    # Get an array of pins for a method name in the provided context. Private
    # and protected methods are excluded by default. Set the `internal`
    # parameter to `true` to include all methods.
    #
    # @param method_name [String] The name of the method
    # @param base_type [String] The context type (e.g., `String` or `Class<String>`)
    # @param internal [Boolean] True if the call came from inside the base type
    # @return [Array<Solargraph::Pin::Base>]
    def infer_method_pins method_name, base_type, internal = false
      get_type_methods(base_type, (internal ? base_type : '')).select{|pin| pin.name == method_name}
    end

    # Get the first pin that matches a method name in the provided context.
    # Private and protected methods are excluded by default. Set the `internal`
    # parameter to `true` to include all methods.
    #
    # @param method_name [String] The name of the method
    # @param base_type [String] The context type (e.g., `String` or `Class<String>`)
    # @param internal [Boolean] True if the call came from inside the base type
    # @return [Solargraph::Pin::Base]
    def infer_method_pin method_name, base_type, internal = false
      infer_method_pins(method_name, base_type, internal).first
    end

    # Infer the type returned by a method in the provided context. Private and
    # protected methods are excluded by default. Set the `internal` parameter
    # to `true` to include all methods.
    #
    # @param method_name [String] The name of the method
    # @param base_type [String] The context type (e.g., `String` or `Class<String>`)
    # @param internal [Boolean] True if the call came from inside the base type
    # @return [String]
    def infer_method_type method_name, base_type, internal = false
      namespace, scope = extract_namespace_and_scope(base_type)
      method = infer_method_pin(method_name, base_type, internal)
      return nil if method.nil?
      method.resolve self
      return namespace if method.name == 'new' and scope == :class
      return base_type if method.return_type == 'self'
      method.return_type
    end

    # def infer_deep_signature_type chain, base_type
    #   return nil if base_type.nil?
    #   internal = true
    #   until chain.empty?
    #     base = chain.shift
    #     base_type = infer_method_type(base, base_type, internal)
    #     return nil if base_type.nil?
    #     internal = false
    #   end
    #   base_type
    # end

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
      skip = []
      if fqns == ''
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
      return Completion.new([], fragment.whole_word_range) if fragment.string? or fragment.comment? or fragment.calculated_signature.start_with?('.')
      result = []
      if !fragment.signature.include?('.')
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
            result.concat resolve_locals(prefer_non_nil_variables(fragment.locals))
            result.concat get_type_methods(combine_type(fragment.namespace, fragment.scope), fragment.namespace)
            result.concat get_type_methods('Kernel')
            result.concat ApiMap.keywords
          end
          result.concat get_constants(fragment.base, fragment.namespace)
        end
      else
        if fragment.signature.include?('::') and !fragment.signature.include?('.')
          result.concat get_constants(fragment.calculated_base, fragment.namespace)
        else
          if fragment.calculated_signature.end_with?('.')
            rest = fragment.calculated_signature.split('.')
          else
            rest = fragment.calculated_base.split('.')
          end
          base = rest.shift
          type = infer_word_type(base, fragment.namespace, scope: fragment.scope)
          unless type.nil?
            rest.each do |m|
              type = infer_method_type(m, type)
              next if type.nil?
            end
            result.concat get_type_methods(type) unless type.nil?
          end
        end
      end
      filtered = result.uniq(&:identifier).select{|s| s.kind != Pin::METHOD or s.name.match(/^[a-z0-9_]*(\!|\?|=)?$/i)}.sort_by.with_index{ |x, idx| [x.name, idx] }
      Completion.new(filtered, fragment.whole_word_range)
    end

    # @param fragment [Solargraph::Source::Fragment]
    # @return [Array<Solargraph::Pin::Base>]
    def define fragment
      return [] if fragment.string? or fragment.comment?
      tail_pins fragment.whole_signature, fragment.namespace, fragment.scope, [:public, :private, :protected]
    end

    # @param fragment [Solargraph::Source::Fragment]
    def signify fragment
      return [] unless fragment.argument?
      return [] if fragment.recipient.whole_signature.nil? or fragment.recipient.whole_signature.empty?
      base, rest = fragment.recipient.whole_signature.split('.', 2)
      return infer_word_pins(base, fragment.recipient.namespace, true) if rest.nil?
      type = nil
      lvar = prefer_non_nil_variables(fragment.locals.select{|pin| pin.name == base}).first
      unless lvar.nil?
        lvar.resolve self
        type = lvar.return_type
        return [] if type.nil?
      end
      type = infer_word_type(base, fragment.namespace, fragment.scope) if type.nil?
      return [] if type.nil?
      ns, sc = extract_namespace_and_scope(type)
      tail_pins(rest, ns, sc, [:public, :private, :protected])
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

    # Convert a namespace and scope into a type.
    #
    # @example
    #   combine_type('String', :instance) => 'String'
    #   combine_type('String', :class)    => 'Class<String>'
    #
    # @param namespace [String]
    # @param scope [Symbol] :class or :instance
    def combine_type namespace, scope
      return '' if namespace.empty?
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

    def query_symbols query
      result = []
      @sources.each do |s|
        result.concat s.query_symbols(query)
      end
      result
    end

    def superclass_of fqns
      found = @superclasses[fqns]
      return nil if found.nil?
      found.resolve self
      found.name
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
        s.namespaces.each do |n|
          namespace_map[n] ||= []
          namespace_map[n].concat s.namespace_pins(n)
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

    # @todo Smelly instance variable access
    def resolve_locals pins
      pins.each do |pin|
        next unless pin.return_type.nil?
        if pin.kind == Pin::BLOCK_PARAMETER and !pin.block.receiver.nil?
          # @todo Scope and visibility might not be correct here
          rcv = tail_pin(pin.block.receiver, pin.block.namespace, :class, [:public])
          next if rcv.nil?
          if CoreFills::METHODS_WITH_YIELDPARAM_SUBTYPES.include?(rcv.path)
            prev = tail_pin(pin.block.receiver.split('.')[0..-2].join('.'), pin.block.namespace, :class, :public)
            next if prev.nil?
            subs = get_subtypes(prev.return_type)
            pin.instance_variable_set(:@return_type, subs[0])
            next
          end
          next if rcv.docstring.nil?
          yps = rcv.docstring.tags(:yieldparam)
          yp = yps[pin.index]
          pin.instance_variable_set(:@return_type, yp.types[0]) unless yp.nil? or yp.types.empty?
        end
      end
    end

    def process_virtual
      unless @virtual_source.nil?
        cache.clear
        namespace_map.clear
        @sources.each do |s|
          s.namespace_pins.each do |pin|
            namespace_map[pin.path] ||= []
            namespace_map[pin.path].push pin
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
      [@namespace_includes.values, @namespace_extends.values].each do |refsets|
        refsets.each do |refs|
          refs.delete_if{|ref| ref.filename == source.filename}
        end
      end
      @superclasses.delete_if{|key, ref| ref.filename == source.filename}
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
      source.namespace_pins.each do |pin|
        @namespace_path_pins[pin.path] ||= []
        @namespace_path_pins[pin.path].push pin
        @namespace_pins[pin.namespace] ||= []
        @namespace_pins[pin.namespace].push pin
        # @todo Determine whether references should be resolve here or
        #   dynamically during queries
        unless pin.superclass_reference.nil?
          @superclasses[pin.path] = pin.superclass_reference
          # pin.superclass_reference.resolve self
        end
        pin.include_references.each do |ref|
          @namespace_includes[pin.path] ||= []
          @namespace_includes[pin.path].push ref
          # ref.resolve self
        end
        pin.extend_references.each do |ref|
          @namespace_extends[pin.path] ||= []
          @namespace_extends[pin.path].push ref
          # ref.resolve self
        end
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
      reqstr = "#{fqns}|#{scope}|#{visibility.sort}|#{deep}"
      return [] if skip.include?(reqstr)
      skip.push reqstr
      result = []
      if scope == :instance
        aps = @attr_pins[fqns]
        result.concat aps unless aps.nil?
      end
      mps = @method_pins[fqns]
      result.concat mps.select{|pin| (pin.scope == scope or fqns == '') and visibility.include?(pin.visibility)} unless mps.nil?
      if deep
        scref = @superclasses[fqns]
        unless scref.nil?
          sc_visi = [:public]
          sc_visi.push :protected if visibility.include?(:protected)
          scref.resolve self
          fqsc = find_fully_qualified_namespace(scref.name, scref.namespace)
          result.concat inner_get_methods(fqsc, scope, sc_visi, true, skip) unless fqsc.nil?
        end
        if scope == :instance
          im = @namespace_includes[fqns]
          unless im.nil?
            im.each do |i|
              i.resolve self
              result.concat inner_get_methods(i.name, scope, visibility, deep, skip) unless i.name.nil?
            end
          end
          result.concat yard_map.get_instance_methods(fqns, visibility: visibility)
          result.concat inner_get_methods('Object', :instance, [:public], deep, skip) unless fqns == 'Object'
        else
          em = @namespace_extends[fqns]
          unless em.nil?
            em.each do |e|
              e.resolve self
              result.concat inner_get_methods(e.name, :instance, visibility, deep, skip) unless e.name.nil?
            end
          end
          result.concat yard_map.get_methods(fqns, '', visibility: visibility)
          type = get_namespace_type(fqns)
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
      result.keep_if{|pin| !pin.name.empty? and visibility.include?(pin.visibility)}
      result.concat yard_map.get_constants(fqns)
      is = @namespace_includes[fqns]
      unless is.nil?
        is.each do |i|
          i.resolve self
          result.concat inner_get_constants(i.name, [:public], skip) unless i.name.nil?
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

    # @todo DRY this method. It's duplicated in CodeMap
    def get_subtypes type
      return [] if type.nil?
      match = type.match(/<([a-z0-9_:, ]*)>/i)
      return [] if match.nil?
      match[1].split(',').map(&:strip)
    end

    # @return [Hash]
    def path_macros
      @path_macros ||= {}
    end

    def current_workspace_sources
      @sources - [@virtual_source]
    end
  end
end
