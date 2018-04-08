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
      # parts = fqns.split('::')
      # subvisi = visibility - [:private]
      # until parts.empty?
      #   subcontext = parts.join('::')
      #   # fqns = find_fully_qualified_namespace(namespace, subcontext)
      #   result.concat inner_get_constants(subcontext, subvisi, skip)
      #   parts.pop
      # end
      # result.concat inner_get_constants('', subvisi, skip)
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
      suggest_unique_variables((@ivar_pins[namespace] || []).select{ |pin| pin.scope == scope })
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

    # @return [Solargraph::Source]
    # def get_source_for(node)
    #   return @virtual_source if !@virtual_source.nil? and @virtual_source.include?(node)
    #   @sources.each do |source|
    #     return source if source.include?(node)
    #   end
    #   nil
    # end


    # @param [Solargraph::Source::Fragment]
    # @return [String]
    def base_type fragment
      select_type fragment, :base
    end

    # @param [Solargraph::Source::Fragment]
    # @return [String]
    def signature_type fragment
      select_type fragment, :signature
    end

    # @param [Solargraph::Source::Fragment]
    # @param target [Symbol] :base or :signature
    # @return [String]
    def select_type fragment, target = :base
      rest = (target == :base ? fragment.base.split('.') : fragment.whole_signature.split('.'))
      base = rest.shift
      base_type = nil
      return nil if base.nil?
      var = find_variable_pin(base, fragment.namespace, fragment.scope)
      if var.nil?
        if base == 'self'
          base_type = combine_type(fragment.namespace, fragment.scope)
        else
          # local variables
          # fragment.local_variable_pins
          var = suggest_unique_variables(fragment.local_variable_pins).select{|pin| pin.name == base}.first
          if var.nil?
            # constants and methods
            var = infer_pin base, fragment.namespace, fragment.scope, [:public, :private, :protected]
            base_type = var.return_type
          end
        end
      else
        var.resolve self
        base_type = var.return_type
      end
      infer_deep_signature_type rest, base_type
    end

    # Find a class, instance, or global variable by name in the provided
    # namespace and scope.
    #
    # @param name [String] The variable name, e.g., `@foo`, `@@bar`, or `$baz`
    # @param fqns [String] The fully qualified namespace
    # @param scope [Symbol] :class or :instance
    # @return [Solargraph::Pin::BaseVariable]
    def find_variable_pin name, fqns, scope
      var = nil
      return nil if name.nil?
      if name.start_with?('@@')
        # class variable
        var = suggest_unique_variables(get_class_variable_pins(fqns)).select{|pin| pin.name == name}.first
        return nil if var.nil?
      elsif name.start_with?('@')
        # instance variable
        var = suggest_unique_variables(get_instance_variable_pins(fqns, scope).select{|pin| pin.name == name}).first
        return nil if var.nil?
      elsif name.start_with?('$')
        # global variable
        var = suggest_unique_variables(get_global_variable_pins.select{|pin| pin.name == name}).first
        return nil if var.nil?
      end
      var
    end

    # Infer a pin from its name in a fully qualified namespace. The result is
    # typically a constant or a method if it exists. This method will return
    #
    # @param name [String] The name of the pin
    # @param fqns [String] The fully qualified namespace
    # @param scope [Symbol] :class or :instance
    # @param visibility [Array<Symbol>] :public, :private, and :protected
    # @param resolve [Boolean] If true, the pin will be fully resolved.
    # @return [Solargraph::Pin::Base]
    def infer_pin name, fqns, scope, visibility, resolve = false
      result = nil
      # constants
      # @todo Better way?
      result = crawl_constants name, fqns, visibility
      if result.nil?
        # methods
        result = get_methods(fqns, scope: scope, visibility: visibility).select{|pin| pin.name == name}.first
      end
      return nil if result.nil?
      result.resolve self if resolve
      result
    end

    def find_namespace_pin fqns
      crawl_constants fqns, '', [:public, :private]
    end

    def crawl_constants name, fqns, visibility
      return nil if name.nil?
      chain = name.split('::')
      cursor = chain.shift
      return nil if cursor.nil?
      unless fqns.empty?
        bases = fqns.split('::')
        result = nil
        until bases.empty?
          built = bases.join('::')
          result = get_constants(built, '').select{|pin| pin.name == cursor and visibility.include?(pin.visibility)}.first
          break unless result.nil?
          bases.pop
          visibility -= [:private]
        end
        return nil if result.nil?
      end
      result = get_constants(fqns, '').select{|pin| pin.name == cursor and visibility.include?(pin.visibility)}.first
      visibility -= [:private]
      until chain.empty? or result.nil?
        fqns = result.path
        cursor = chain.shift
        result = get_constants(fqns, '').select{|pin| pin.name == cursor and visibility.include?(pin.visibility)}.first
      end
      result
    end

    def infer_type signature, context = '', scope: :instance
      visibility = [:public]
      visibility.push :private, :protected unless context.empty?
      rest = signature.split('.')
      base = rest.shift
      pin = nil
      if base == 'self'
        pin = find_namespace_pin(context)
        # @todo This should never happen, probably?
        return nil if pin.nil?
        return infer_deep_signature_type(rest, pin.path) if scope == :instance
        return infer_deep_signature_type(rest, pin.return_type)
      end
      pin = find_variable_pin(base, context, scope) if pin.nil?
      pin = infer_pin base, context, scope, visibility if pin.nil?
      pin = infer_pin base, '', :instance, [:public] if pin.nil?
      return nil if pin.nil?
      pin.resolve self
      infer_deep_signature_type rest, pin.return_type
    end

    # @return [Solargraph::Pin::Base]
    def tail_pin signature, fqns, scope, visibility
      return infer_pin(signature, fqns, scope, [:public, :private, :protected]) unless signature.include?('.')
      parts = signature.split('.')
      last = parts.pop
      base = parts.join('.')
      type = infer_type(base, fqns, scope: :scope)
      return nil if type.nil?
      subns, subsc = extract_namespace_and_scope(type)
      infer_pin(last, subns, subsc, [:public, :private, :protected])
    end

    def infer_deep_signature_type chain, base_type
      return nil if base_type.nil?
      result = base_type
      until chain.empty?
        base = chain.shift
        method = get_type_methods(result, '').select{|pin| pin.name == base}.first
        return nil if method.nil?
        if method.name == 'new'
          namespace, scope = extract_namespace_and_scope(result)
          if scope == :class
            result = namespace
            next
          end
        end
        method.resolve self
        next if method.return_type == 'self'
        result = method.return_type
        break if result.nil?
      end
      result
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
    # def infer_signature_type signature, namespace, scope = :class
    #   return nil if signature.start_with?('.')
    #   base, rest = signature.split('.', 2)
    #   if base == 'self'
    #     if rest.nil?
    #       combine_type(namespace, scope)
    #     else
    #       inner_infer_signature_type(rest, namespace, scope, false)
    #     end
    #   else
    #     # @todo What to do about the call node here? We probably don't need
    #     #   it since the fragment methods are responsible for local variables
    #     pins = infer_signature_pins(base, namespace, scope)
    #     return nil if pins.empty?
    #     pin = pins.first
    #     if rest.nil?
    #       pin.resolve self
    #       pin.return_type
    #     elsif pin.signature.nil? or pin.signature.empty?
    #       if pin.path.nil?
    #         pin.resolve self
    #         fqtype = find_fully_qualified_type(pin.return_type, namespace)
    #         return nil if fqtype.nil?
    #         subns, subsc = extract_namespace_and_scope(fqtype)
    #         inner_infer_signature_type(rest, subns, subsc, true)
    #       else
    #         subns, subsc = extract_namespace_and_scope(pin.return_type)
    #         inner_infer_signature_type(rest, subns, subsc, true)
    #       end
    #     else
    #       subtype = inner_infer_signature_type(pin.signature, namespace, scope, true)
    #       subns, subsc = extract_namespace_and_scope(subtype)
    #       inner_infer_signature_type(rest, subns, subsc, false)
    #     end
    #   end
    # end

    # @param fragment [Solargraph::Source::Fragment]
    # @return [ApiMap::Completion]
    def complete fragment
      return Completion.new([], fragment.whole_word_range) if fragment.string? or fragment.comment? or fragment.signature.start_with?('.')
      result = []
      
      result = []
      if fragment.base.empty?
        if fragment.signature.start_with?('@@')
          result.concat get_class_variable_pins(fragment.namespace)
        elsif fragment.signature.start_with?('@')
          result.concat get_instance_variable_pins(fragment.namespace, fragment.scope)
        elsif fragment.signature.start_with?('$')
          result.concat suggest_unique_variables(get_global_variable_pins)
        elsif fragment.signature.start_with?(':') and !fragment.signature.start_with?('::')
          result.concat get_symbols
        else
          unless fragment.signature.include?('::')
            result.concat suggest_unique_variables(fragment.local_variable_pins)
            result.concat get_type_methods(combine_type(fragment.namespace, fragment.scope), fragment.namespace)
            result.concat ApiMap.keywords
          end
          result.concat get_constants(fragment.base, fragment.namespace)
        end
      else
        if fragment.signature.include?('::') and !fragment.signature.include?('.')
          result.concat get_constants(fragment.base, fragment.namespace)
        else
          lvars = suggest_unique_variables(fragment.local_variable_pins)
          base, rest = fragment.signature.split('.')
          match = lvars.select{|pin| pin.name == base}.first
          if match.nil?
            result.concat lvars unless fragment.signature.include?('.')
            type = infer_type(fragment.base, fragment.namespace, scope: fragment.scope)
            result.concat get_type_methods(type)
          else
            match.resolve self
            result.concat get_type_methods(match.return_type, '')
          end
        end
      end
      filtered = result.uniq(&:identifier).select{|s| s.kind != Solargraph::LanguageServer::CompletionItemKinds::METHOD or s.name.match(/^[a-z0-9_]*(\!|\?|=)?$/i)}.sort_by.with_index{ |x, idx| [x.name, idx] }
      Completion.new(filtered, fragment.whole_word_range)
    end

    def define fragment
      return [] if fragment.string? or fragment.comment?
      pins = infer_signature_pins fragment.whole_signature, fragment.namespace, fragment.scope
      return pins if pins.empty?
      if pins.first.variable?
        result = []
        pins.select{|pin| pin.variable?}.each do |pin|
          pin.resolve self
          result.concat infer_signature_pins(pin.return_type, fragment.namespace, fragment.scope)
        end
        result
      else
        pins.reject{|pin| pin.path.nil?}
      end
    end

    def signify fragment
      return [] unless fragment.argument?
      pins = infer_signature_pins(fragment.recipient.whole_signature, fragment.recipient.namespace, fragment.recipient.scope)
      pins
    end

    # Infer the type from the fragment's base.
    #
    # @param fragment [Solargraph::Source::Fragment]
    # @return [String] The inferred type.
    # def infer fragment
    #   base, rest = fragment.base.split('.', 2)
    #   lvar = suggest_unique_variables(fragment.local_variable_pins.select{|pin| pin.name == base}).first
    #   if lvar.nil?
    #     infer_signature_type fragment.base, fragment.namespace, fragment.scope
    #   else
    #     lvar.resolve self
    #     lvar.return_type
    #   end
    # end

    def infer_signature_pins signature, namespace, scope #, call_node
      return [] if signature.nil? or signature.empty?
      base, rest = signature.split('.', 2)
      if base.start_with?('@@')
        pin = get_class_variable_pins(namespace).select{|pin| pin.name == base}.first
        return [] if pin.nil?
        return [pin] if rest.nil?
        fqns = find_fully_qualified_namespace(pin.return_type, namespace)
        return [] if fqns.nil?
        return inner_infer_signature_pins rest, namespace, scope, false
      elsif base.start_with?('@')
        pin = get_instance_variable_pins(namespace, scope).select{|pin| pin.name == base}.first
        return [] if pin.nil?
        pin.resolve self
        return [pin] if rest.nil?
        fqtype = find_fully_qualified_type(pin.return_type, namespace)
        return [] if fqtype.nil?
        subns, subsc = extract_namespace_and_scope(fqtype)
        return inner_infer_signature_pins rest, subns, subsc, false
      elsif base.start_with?('$')
        # @todo globals
      else
        type = find_fully_qualified_namespace(base, namespace)
        unless type.nil?
          if rest.nil?
            return get_path_suggestions(type)
          else
            return inner_infer_signature_pins rest, type, :class, false
          end
        end
        # source = get_source_for(call_node)
        # unless source.nil?
        #   lvpins = suggest_unique_variables(source.local_variable_pins.select{|pin| pin.name == base and pin.visible_from?(call_node)})
        #   unless lvpins.empty?
        #     if rest.nil?
        #       return lvpins
        #     else
        #       lvp = lvpins.first
        #       lvp.resolve self
        #       type = lvp.return_type
        #       unless type.nil?
        #         fqtype = find_fully_qualified_type(type, namespace)
        #         return [] if fqtype.nil?
        #         subns, subsc = extract_namespace_and_scope(fqtype)
        #         return inner_infer_signature_pins(rest, subns, subsc, call_node, false)
        #       end
        #     end
        #   end
        # end
        return inner_infer_signature_pins signature, namespace, scope, true
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
          refs.delete_if{|ref| ref.pin.filename == source.filename}
        end
      end
      @superclasses.delete_if{|key, ref| ref.pin.filename == source.filename}
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
      if fqns != '' and scope == :class and !result.map(&:path).include?("#{fqns}.new")
        # Create a [Class].new method pin from [Class]#initialize
        init = inner_get_methods(fqns, :instance, [:private], deep, skip - [fqns]).select{|pin| pin.name == 'initialize'}.first
        unless init.nil?
          result.unshift Solargraph::Pin::Directed::Method.new(init.source, init.node, init.namespace, :class, :public, init.docstring, 'new', init.namespace)
        end
      end
      if deep
        scref = @superclasses[fqns]
        unless scref.nil?
          sc_visi = [:public]
          sc_visi.push :protected if visibility.include?(:protected)
          # sc_fqns = find_fully_qualified_namespace(sc, fqns)
          scref.resolve self
          result.concat inner_get_methods(scref.name, scope, sc_visi, true, skip) unless scref.name.nil?
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

    # def inner_infer_signature_type signature, namespace, scope, top
    #   namespace ||= ''
    #   # if cache.has_signature_type?(signature, namespace, scope)
    #   #   return cache.get_signature_type(signature, namespace, scope)
    #   # end
    #   return nil if signature.nil?
    #   return combine_type(namespace, scope) if signature.empty?
    #   # return namespace if signature.empty? and scope == :instance
    #   # return nil if signature.empty? # @todo This might need to return Class<namespace>
    #   if !signature.include?('.')
    #     fqns = find_fully_qualified_namespace(signature, namespace)
    #     unless fqns.nil? or fqns.empty?
    #       type = (get_namespace_type(fqns) == :class ? 'Class' : 'Module')
    #       return "#{type}<#{fqns}>"
    #     end
    #   end
    #   result = nil
    #   parts = signature.split('.', 2)
    #   type = find_fully_qualified_namespace(parts[0], namespace)
    #   if type.nil?
    #     # It's a variable or method call
    #     # @todo This self check might not be necessary. In fact, everything
    #     #   that happens at the top should probably be in the infer_* method.
    #     if top and parts[0] == 'self'
    #       if parts[1].nil?
    #         result = namespace
    #       else
    #         return inner_infer_signature_type(parts[1], namespace, scope, false)
    #       end
    #     elsif parts[0] == 'new' and scope == :class
    #       scope = :instance
    #       if parts[1].nil?
    #         result = namespace
    #       else
    #         result = inner_infer_signature_type(parts[1], namespace, :instance, false)
    #       end
    #     else
    #       visibility = [:public]
    #       visibility.concat [:private, :protected] if top
    #       if scope == :instance || namespace == ''
    #         tmp = get_methods(extract_namespace(namespace), visibility: visibility)
    #       else
    #         tmp = get_methods(namespace, visibility: visibility, scope: :class)
    #         # tmp = get_type_methods(namespace, (top ? namespace : ''))
    #       end
    #       tmp.concat get_methods('Kernel', visibility: [:public]) if top
    #       matches = tmp.select{|s| s.name == parts[0]}
    #       return nil if matches.empty?
    #       # @todo Handle macros elsewhere
    #       # matches.each do |m|
    #       #   type = get_return_type_from_macro(namespace, signature, call_node, scope, visibility)
    #       #   if type.nil?
    #       #     if METHODS_RETURNING_SELF.include?(m.path)
    #       #       type = curtype
    #       #     elsif METHODS_RETURNING_SUBTYPES.include?(m.path)
    #       #       subtypes = get_subtypes(namespace)
    #       #       type = subtypes[0]
    #       #     elsif !m.return_type.nil?
    #       #       if m.return_type == 'self'
    #       #         type = combine_type(namespace, scope)
    #       #       else
    #       #         type = m.return_type
    #       #       end
    #       #     end
    #       #   end
    #       #   break unless type.nil?
    #       # end

    #       # @todo Should this iterate through all the matches? Probably not.
    #       matches.first.resolve self
    #       type = matches.first.return_type
    #       type = combine_type(namespace, scope) if type == 'self'
    #       unless type.nil?
    #         scope = :instance
    #         if parts[1].nil?
    #           result = type
    #         else
    #           subns, subsc = extract_namespace_and_scope(type)
    #           result = inner_infer_signature_type(parts[1], subns, subsc, false)
    #         end
    #       end
    #     end
    #   else
    #     return inner_infer_signature_type(parts[1], type, :class, false)
    #   end
    #   unless result.nil?
    #     if scope == :class
    #       nstype = get_namespace_type(result)
    #       result = "#{nstype == :class ? 'Class<' : 'Module<'}#{result}>"
    #     end
    #   end
    #   cache.set_signature_type signature, namespace, scope, result
    #   result
    # end

    # @todo call_node might be superfluous here. We're already past looking for local variables.
    # def inner_infer_signature_pins signature, namespace, scope, top
    #   base, rest = signature.split('.', 2)
    #   type = nil
    #   if rest.nil?
    #     visibility = [:public]
    #     visibility.push :private, :protected if top
    #     methods = []
    #     methods.concat get_methods(namespace, visibility: visibility, scope: scope).select{|pin| pin.name == base}
    #     methods.concat get_methods('Kernel', scope: :instance).select{|pin| pin.name == base} if top
    #     return methods
    #   else
    #     type = inner_infer_signature_type base, namespace, scope, top
    #     nxt_ns, nxt_scope = extract_namespace_and_scope(type)
    #     return inner_infer_signature_pins rest, nxt_ns, nxt_scope, false
    #   end
    # end

    def current_workspace_sources
      @sources - [@virtual_source]
    end
  end
end
