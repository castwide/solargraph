require 'yard'

module Solargraph
  # The YardMap provides access to YARD documentation for the Ruby core, the
  # stdlib, and gems.
  #
  class YardMap
    autoload :Cache, 'solargraph/yard_map/cache'
    autoload :CoreDocs, 'solargraph/yard_map/core_docs'

    CoreDocs.require_minimum
    @@stdlib_yardoc = CoreDocs.yard_stdlib_file
    @@stdlib_paths = {}
    YARD::Registry.load! @@stdlib_yardoc
    YARD::Registry.all(:class, :module).each do |ns|
      next if ns.file.nil?
      path = ns.file.sub(/^(ext|lib)\//, '').sub(/\.(rb|c)$/, '')
      next if path.start_with?('-')
      @@stdlib_paths[path] ||= []
      @@stdlib_paths[path].push ns
    end

    # @return [Solargraph::Workspace]
    attr_reader :workspace

    # @return [Array<String>]
    attr_reader :required

    def initialize required: [], workspace: nil
      @workspace = workspace
      # HACK: YardMap needs its own copy of this array
      @required = required.clone
      @namespace_yardocs = {}
      @gem_paths = {}
      @stdlib_namespaces = []
      process_requires
      yardocs.push CoreDocs.yardoc_file
      yardocs.uniq!
      yardocs.delete_if{ |y| y.start_with? workspace.directory } unless workspace.nil? or workspace.directory.nil?
      yardocs.each do |y|
        load_yardoc y
        YARD::Registry.all(:class, :module).each do |ns|
          @namespace_yardocs[ns.path] ||= []
          @namespace_yardocs[ns.path].push y
        end
      end
      cache_core
    end

    # @return [Array<String>]
    def yardocs
      @yardocs ||= []
    end

    # @return [Array<String>]
    def unresolved_requires
      @unresolved_requires ||= []
    end

    # @param y [String]
    # @return [YARD::Registry]
    def load_yardoc y
      begin
        if y.kind_of?(Array)
          YARD::Registry.load y, true
        else
          YARD::Registry.load! y
        end
      rescue Exception => e
        STDERR.puts "Error loading yardoc '#{y}' #{e.class} #{e.message}"
        yardocs.delete y
        nil
      end
    end

    # @param query [String]
    # @return [Array<String>]
    def search query
      found = []
      (yardocs + [@@stdlib_yardoc]).each { |y|
        yard = load_yardoc(y)
        unless yard.nil?
          yard.paths.each do |p|
            if found.empty? or (query.include?('.') or query.include?('#')) or !(p.include?('.') or p.include?('#'))
              found.push p if p.downcase.include?(query.downcase)
            end
          end
        end
      }
      found.uniq
    end

    # @param query [String]
    # @return [YARD::CodeObjects::Base]
    def document query
      found = []
      (yardocs + [@@stdlib_yardoc]).each { |y|
        yard = load_yardoc(y)
        unless yard.nil?
          obj = yard.at query
          found.push obj unless obj.nil?
        end
      }
      found
    end

    # @param namespace [String]
    # @param scope [String]
    # @return [Array<Solargraph::Pin::Base>]
    def get_constants namespace , scope = ''
      cached = cache.get_constants(namespace, scope)
      return cached unless cached.nil?
      consts = []
      result = []
      combined_namespaces(namespace, scope).each do |ns|
        yardocs_documenting(ns).each do |y|
          # @todo Getting constants from the stdlib works slightly differently
          #   from methods
          next if y == @@stdlib_yardoc
          yard = load_yardoc(y)
          unless yard.nil?
            found = yard.at(ns)
            consts.concat found.children unless found.nil?
          end
        end
        consts.concat @stdlib_namespaces.select{|ns| ns.namespace.path == namespace}
      end
      consts.each { |c|
        detail = nil
        kind = nil
        return_type = nil
        if c.kind_of?(YARD::CodeObjects::ClassObject)
          detail = 'Class'
          return_type = "Class<#{c.to_s}>"
        elsif c.kind_of?(YARD::CodeObjects::ModuleObject)
          detail = 'Module'
          return_type = "Module<#{c.to_s}>"
        elsif c.kind_of?(YARD::CodeObjects::ConstantObject)
          detail = 'Constant'
        else
          next
        end
        result.push Pin::YardObject.new(c, object_location(c))
      }
      cache.set_constants(namespace, scope, result)
      result
    end

    # @param namespace [String]
    # @param scope [String]
    # @param visibility [Array<Symbol>]
    # @return [Array<Solargraph::Pin::Base>]
    def get_methods namespace, scope = '', visibility: [:public]
      return [] if namespace == '' and scope == ''
      cached = cache.get_methods(namespace, scope, visibility)
      return cached unless cached.nil?
      meths = []
      combined_namespaces(namespace, scope).each do |ns|
        yardocs_documenting(ns).each do |y|
          yard = load_yardoc(y)
          unless yard.nil?
            ns = nil
            ns = find_first_resolved_object(yard, namespace, scope)
            unless ns.nil?
              has_new = false
              ns.meths(scope: :class, visibility: visibility).each { |m|
                has_new = true if m.name == 'new'
                meths.push Pin::YardObject.new(m, object_location(m))
              }
              # HACK: Convert #initialize to .new
              if visibility.include?(:public) and !has_new
                init = ns.meths(scope: :instance).select{|m| m.to_s.split(/[\.#]/).last == 'initialize'}.first
                unless init.nil?
                  ip = Solargraph::Pin::YardObject.new(init, object_location(init))
                  np = Solargraph::Pin::Method.new(ip.location, ip.namespace, 'new', ip.docstring, :class, :public, ip.parameters)
                  meths.push np
                end
              end
              # Collect superclass methods
              if ns.kind_of?(YARD::CodeObjects::ClassObject) and !ns.superclass.nil?
                meths += get_methods ns.superclass.to_s, '', visibility: [:public, :protected] unless ['Object', 'BasicObject', ''].include?(ns.superclass.to_s)
              end
            end
          end
        end
      end
      cache.set_methods(namespace, scope, visibility, meths)
      meths
    end

    # @param namespace [String]
    # @param scope [String]
    # @param visibility [Array<Symbol>]
    # @return [Array<Solargraph::Pin::Base>]
    def get_instance_methods namespace, scope = '', visibility: [:public]
      return [] if namespace == '' and scope == ''
      cached = cache.get_instance_methods(namespace, scope, visibility)
      return cached unless cached.nil?
      meths = []
      combined_namespaces(namespace, scope).each do |ns|
        yardocs_documenting(ns).each do |y|
          yard = load_yardoc(y)
          unless yard.nil?
            ns = nil
            ns = find_first_resolved_object(yard, namespace, scope)
            unless ns.nil?
              ns.meths(scope: :instance, visibility: visibility).each do |m|
                n = m.to_s.split(/[\.#]/).last
                # HACK: Exception for Module#module_function in Class
                next if ns.name == :Class and m.path == 'Module#module_function'
                # HACK: Special treatment for #initialize
                next if n == 'initialize' and !visibility.include?(:private)
                if (namespace == 'Kernel' or !m.to_s.start_with?('Kernel#')) and !m.docstring.to_s.include?(':nodoc:')
                  meths.push Pin::YardObject.new(m, object_location(m))
                end
              end
              if ns.kind_of?(YARD::CodeObjects::ClassObject) and namespace != 'Object'
                unless ns.nil?
                  meths += get_instance_methods(ns.superclass.to_s)
                end
              end
              ns.instance_mixins.each do |m|
                meths += get_instance_methods(m.to_s) unless m.to_s == 'Kernel'
              end
              # HACK: Now get the #initialize method for private requests
              if visibility.include?(:private)
                init = ns.meths(scope: :instance).select{|m| m.to_s.split(/[\.#]/).last == 'initialize'}.first
                meths.push Pin::YardObject.new(init, object_location(init)) unless init.nil?
              end
            end
          end
        end
      end
      cache.set_instance_methods(namespace, scope, visibility, meths)
      meths
    end

    # @param namespace [String]
    # @param scope [String]
    # @return [String]
    def find_fully_qualified_namespace namespace, scope
      unless scope.nil? or scope.empty?
        parts = scope.split('::')
        while parts.length > 0
          here = "#{parts.join('::')}::#{namespace}"
          return here unless yardocs_documenting(here).empty?
          return here if @stdlib_namespaces.any?{|ns| ns.path == here}
          parts.pop
        end
      end
      return namespace unless yardocs_documenting(namespace).empty?
      return namespace if @stdlib_namespaces.any?{|ns| ns.path == namespace}
      nil
    end

    # @param path [String]
    # @param space [String]
    # @return [Array<Pin::YardObject>]
    def objects path, space = ''
      cached = cache.get_objects(path, space)
      return cached unless cached.nil?
      result = []
      yardocs.each { |y|
        yard = load_yardoc(y)
        unless yard.nil?
          obj = find_first_resolved_object(yard, path, space)
          unless obj.nil?
            result.push Pin::YardObject.new(obj, object_location(obj))
          end
        end
      }
      @stdlib_namespaces.each do |ns|
        result.push Pin::YardObject.new(ns, object_location(ns)) if ns.path == path
      end
      cache.set_objects(path, space, result)
      result
    end

    # @param fqns [String]
    # @return [Symbol] :class, :module, or nil
    def get_namespace_type(fqns)
      yardocs_documenting(fqns).each do |y|
        yard = load_yardoc y
        unless yard.nil?
          obj = yard.at(fqns)
          unless obj.nil?
            return :class if obj.kind_of?(YARD::CodeObjects::ClassObject)
            return :module if obj.kind_of?(YARD::CodeObjects::ModuleObject)
            return nil
          end
        end
      end
      nil
    end

    private

    # @return [Solargraph::YardMap::Cache]
    def cache
      @cache ||= Cache.new
    end

    def find_first_resolved_object yard, namespace, scope
      unless scope.nil?
        parts = scope.split('::')
        while parts.length > 0
          ns = yard.resolve(P(parts.join('::')), namespace, true)
          return ns unless ns.nil?
          parts.pop
        end
      end
      yard.at(namespace)
    end

    def cache_core
      get_constants '', ''
    end

    def process_requires
      tried = []
      unresolved_requires.clear
      required.each do |r|
        next if r.nil?
        next if !workspace.nil? and workspace.would_require?(r)
        begin
          spec = Gem::Specification.find_by_path(r) || Gem::Specification.find_by_name(r.split('/').first)
          ver = spec.version.to_s
          ver = ">= 0" if ver.empty?
          add_gem_dependencies spec
          yd = YARD::Registry.yardoc_file_for_gem(spec.name, ver)
          @gem_paths[spec.name] = spec.full_gem_path
          unresolved_requires.push r if yd.nil?
          yardocs.unshift yd unless yd.nil? or yardocs.include?(yd)
        rescue Gem::LoadError => e
          next if !workspace.nil? and workspace.would_require?(r)
          stdnames = []
          @@stdlib_paths.each_pair do |path, objects|
            stdnames.concat objects if path == r or path.start_with?("#{r}/")
          end
          @stdlib_namespaces.concat stdnames
          unresolved_requires.push r if stdnames.empty?
        end
      end
    end

    # @param spec [Gem::Specification]
    def add_gem_dependencies spec
      (spec.dependencies - spec.development_dependencies).each do |dep|
        spec = Gem::Specification.find_by_name(dep.name)
        @gem_paths[spec.name] = spec.full_gem_path unless spec.nil?
        gy = YARD::Registry.yardoc_file_for_gem(dep.name)
        if gy.nil?
          unresolved_requires.push dep.name
        else
          yardocs.unshift gy unless yardocs.include?(gy)
        end
      end
    end

    # @param namespace [String]
    # @param scope [String]
    # @return [Array<String>]
    def combined_namespaces namespace, scope = ''
      combined = [namespace]
      unless scope.empty?
        parts = scope.split('::')
        until parts.empty?
          combined.unshift parts.join('::') + '::' + namespace
          parts.pop
        end
      end
      combined
    end

    # @param namespace [String]
    # @return [Array<String>]
    def yardocs_documenting namespace
      result = []
      if namespace == ''
        result.concat yardocs
      else
        result.concat @namespace_yardocs[namespace] unless @namespace_yardocs[namespace].nil?
      end
      if @stdlib_namespaces.map(&:path).include?(namespace)
        result.push @@stdlib_yardoc
      end
      result
    end

    # @param obj [YARD::CodeObjects::Base]
    # @return [Solargraph::Source::Location, nil]
    def object_location obj
      return nil if obj.file.nil? or obj.line.nil?
      @gem_paths.values.each do |path|
        file = File.join(path, obj.file)
        return Solargraph::Source::Location.new(file, Solargraph::Source::Range.from_to(obj.line - 1, 0, obj.line - 1, 0)) if File.exist?(file)
      end
      nil
    end
  end
end
