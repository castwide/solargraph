require 'parser/current'
require 'yard'

module Solargraph
  class YardMap
    @@stdlib_yardoc = File.join(Dir.home, '.solargraph', 'cache', '2.0.0', 'yardoc-stdlib')
    @@stdlib_namespaces = []
    YARD::Registry.load! @@stdlib_yardoc
    YARD::Registry.all(:class, :module).each do |ns|
      @@stdlib_namespaces.push ns.path
    end

    autoload :Cache, 'solargraph/yard_map/cache'

    attr_reader :workspace
    attr_reader :required

    def initialize required: [], workspace: nil
      @workspace = workspace
      used = []
      @required = required
      @namespace_yardocs = {}
      if @required.include?('bundler/setup')
        yardocs.concat bundled_gem_yardocs
      else
        @required.each do |r|
          if workspace.nil? or !File.exist?(File.join workspace, 'lib', "#{r}.rb")
            g = r.split('/').first
            unless used.include?(g)
              used.push g
              gy = YARD::Registry.yardoc_file_for_gem(g)
              if gy.nil?
                STDERR.puts "Required path not found: #{r}"
              else
                #STDERR.puts "Adding #{gy}"
                yardocs.unshift gy
                add_gem_dependencies g
              end
            end
          end
        end
      end
      yardocs.push File.join(Dir.home, '.solargraph', 'cache', '2.0.0', 'yardoc')
      #yardocs.push File.join(Dir.home, '.solargraph', 'cache', '2.0.0', 'yardoc-stdlib')
      yardocs.uniq!
      yardocs.each do |y|
        load_yardoc y
        YARD::Registry.all(:class, :module).each do |ns|
          @namespace_yardocs[ns.path] ||= []
          @namespace_yardocs[ns.path].push y
        end
      end
      cache_core
    end

    # @return [Solargraph::LiveMap]
    def live_map
      @live_map ||= Solargraph::LiveMap.new
    end

    # @return [Array<String>]
    def yardocs
      @yardocs ||= []
    end

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
    def search query
      found = []
      (yardocs + [@@stdlib_yardoc]).each { |y|
        yard = load_yardoc(y)
        unless yard.nil?
          yard.paths.each { |p|
            found.push p if p.downcase.include?(query.downcase)
          }
        end
      }
      found.sort
    end

    # @param query [String]
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

    # @return [Array<Suggestion>]
    def get_constants namespace , scope = ''
      cached = cache.get_constants(namespace, scope)
      return cached unless cached.nil?
      consts = []
      result = []
      combined_namespaces(namespace, scope).each do |ns|
        yardocs_documenting(ns).each do |y|
          yard = load_yardoc(y)
          unless yard.nil?
            found = yard.at(ns)
            consts.concat found.children unless found.nil?
          end
        end
      end
      consts.each { |c|
        detail = nil
        kind = nil
        if c.kind_of?(YARD::CodeObjects::ClassObject)
          detail = 'Class'
          kind = Suggestion::CLASS
        elsif c.kind_of?(YARD::CodeObjects::ModuleObject)
          detail = 'Module'
          kind = Suggestion::MODULE
        elsif c.kind_of?(YARD::CodeObjects::ConstantObject)
          detail = 'Constant'
          kind = Suggestion::CONSTANT
        else
          next
        end
        result.push Suggestion.new(c.to_s.split('::').last, detail: detail, kind: kind, docstring: c.docstring)
      }
      cache.set_constants(namespace, scope, result)
      result
    end

    # @return [Array<Suggestion>]
    def get_methods namespace, scope = '', visibility: [:public]
      cached = cache.get_methods(namespace, scope, visibility)
      return cached unless cached.nil?
      meths = []
      combined_namespaces(namespace, scope).each do |ns|
        yardocs_documenting(ns).each do |y|
          yard = load_yardoc(y)
          unless yard.nil?
            ns = nil
            ns = find_first_resolved_namespace(yard, namespace, scope)
            unless ns.nil?
              ns.meths(scope: :class, visibility: visibility).each { |m|
                n = m.to_s.split(/[\.#]/).last.gsub(/=/, ' = ')
                label = "#{n}"
                args = get_method_args(m)
                kind = (m.is_attribute? ? Suggestion::FIELD : Suggestion::METHOD)
                meths.push Suggestion.new(label, insert: "#{n.gsub(/=/, ' = ')}", kind: kind, docstring: m.docstring, code_object: m, detail: "#{ns}", location: "#{m.file}:#{m.line}", arguments: args)
              }
              # Collect superclass methods
              if ns.kind_of?(YARD::CodeObjects::ClassObject) and !ns.superclass.nil?
                meths += get_methods ns.superclass.to_s, '', visibility: [:public, :protected] unless ['Object', 'BasicObject', ''].include?(ns.superclass.to_s)
              end
              if ns.kind_of?(YARD::CodeObjects::ClassObject) and namespace != 'Class'
                meths += get_instance_methods('Class')
                yard = load_yardoc(y)
                i = yard.at("#{ns}#initialize")
                unless i.nil?
                  meths.delete_if{|m| m.label == 'new'}
                  label = "#{i}"
                  args = get_method_args(i)
                  meths.push Suggestion.new('new', kind: Suggestion::METHOD, docstring: i.docstring, code_object: i, detail: "#{ns}", location: "#{i.file}:#{i.line}", arguments: args)
                end
              end
            end
          end
        end
      end
      cache.set_methods(namespace, scope, visibility, meths)
      meths
    end

    # @return [Array<Suggestion>]
    def get_instance_methods namespace, scope = '', visibility: [:public]
      cached = cache.get_instance_methods(namespace, scope, visibility)
      return cached unless cached.nil?
      meths = []
      combined_namespaces(namespace, scope).each do |ns|
        yardocs_documenting(ns).each do |y|
          yard = load_yardoc(y)
          unless yard.nil?
            ns = nil
            ns = find_first_resolved_namespace(yard, namespace, scope)
            unless ns.nil?
              ns.meths(scope: :instance, visibility: visibility).each { |m|
                n = m.to_s.split(/[\.#]/).last
                if n.to_s.match(/^[a-z]/i) and (namespace == 'Kernel' or !m.to_s.start_with?('Kernel#')) and !m.docstring.to_s.include?(':nodoc:')
                  label = "#{n}"
                  args = get_method_args(m)
                  kind = (m.is_attribute? ? Suggestion::FIELD : Suggestion::METHOD)
                  meths.push Suggestion.new(label, insert: "#{n.gsub(/=/, ' = ')}", kind: kind, docstring: m.docstring, code_object: m, detail: m.namespace, location: "#{m.file}:#{m.line}", arguments: args)
                end
              }
              if ns.kind_of?(YARD::CodeObjects::ClassObject) and namespace != 'Object'
                unless ns.nil?
                  meths += get_instance_methods(ns.superclass.to_s)
                end
              end
              ns.instance_mixins.each do |m|
                meths += get_instance_methods(m.to_s) unless m.to_s == 'Kernel'
              end
            end
          end
        end
      end
      cache.set_instance_methods(namespace, scope, visibility, meths)
      meths
    end

    def gem_names
      Gem::Specification.map{ |s| s.name }.uniq
    end

    def find_fully_qualified_namespace namespace, scope
      yardocs.each { |y|
        yard = load_yardoc(y)
        unless yard.nil?
          obj = find_first_resolved_namespace(yard, namespace, scope)
          return obj.path unless obj.nil? or !obj.kind_of?(YARD::CodeObjects::NamespaceObject)
        end
      }
      nil
    end

    def objects path, space = ''
      result = []
      yardocs.each { |y|
        yard = load_yardoc(y)
        unless yard.nil?
          obj = find_first_resolved_namespace(yard, path, space)
          if obj.nil? and path.include?('#')
            parts = path.split('#')
            obj = yard.at(parts[0])
            unless obj.nil?
              meths = obj.meths(scope: [:instance]).keep_if{|m| m.name.to_s == parts[1]}
              meths.each do |m|
                args = get_method_args(m)
                result.push Solargraph::Suggestion.new(m.name, kind: 'Method', detail: m.path, code_object: m, arguments: args)
              end
            end
          else
            unless obj.nil?
              args = []
              args = get_method_args(obj) if obj.kind_of?(YARD::CodeObjects::MethodObject)
              kind = kind_of_object(obj)
              result.push Solargraph::Suggestion.new(obj.name, kind: kind, detail: obj.path, code_object: obj, arguments: args)
            end
          end
        end
      }
      result
    end

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

    def bundled_gem_yardocs
      result = []
      unless workspace.nil?
        Bundler.with_clean_env do
          Bundler.environment.chdir(workspace) do
            glfn = File.join(workspace, 'Gemfile.lock')
            spec_versions = {}
            if File.file?(glfn)
              lockfile = Bundler::LockfileParser.new(Bundler.read_file(glfn))
              lockfile.specs.each do |s|
                spec_versions[s.name] = s.version.to_s
              end
            end
            Bundler.environment.dependencies.each do |s|
              if s.type == :runtime
                ver = spec_versions[s.name]
                y = YARD::Registry.yardoc_file_for_gem(s.name, ver)
                if y.nil?
                  STDERR.puts "Bundled gem not found: #{s.name}, #{ver}"
                else
                  #STDERR.puts "Adding #{y}"
                  result.push y
                  add_gem_dependencies(s.name)
                end
              end
            end
          end
        end
      end
      result.uniq
    end

    private

    def cache
      @cache ||= Cache.new
    end

    def get_method_args meth
      args = []
      meth.parameters.each { |a|
        p = a[0]
        unless a[1].nil?
          p += ' =' unless p.end_with?(':')
          p += " #{a[1]}"
        end
        args.push p
      }
      args
    end

    def find_first_resolved_namespace yard, namespace, scope
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

    def kind_of_object obj
      if obj.kind_of?(YARD::CodeObjects::MethodObject)
        'Method'
      elsif obj.kind_of?(YARD::CodeObjects::ClassObject)
        'Class'
      elsif obj.kind_of?(YARD::CodeObjects::ModuleObject)
        'Module'
      else
        nil
      end
    end

    def add_gem_dependencies gem_name
      spec = Gem::Specification.find_by_name(gem_name)
      spec.nondevelopment_dependencies.each do |dep|
        gy = YARD::Registry.yardoc_file_for_gem(dep.name)
        if gy.nil?
          STDERR.puts "Required path not found: #{dep.name}"
        else
          #STDERR.puts "Adding #{gy}"
          yardocs.unshift gy
        end
      end
    end

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

    def yardocs_documenting namespace
      result = []
      if namespace == ''
        result.concat yardocs
      else
        result.concat @namespace_yardocs[namespace] unless @namespace_yardocs[namespace].nil?
      end
      result.push @@stdlib_yardoc if result.empty? and @@stdlib_namespaces.include?(namespace)
      result
    end
  end
end
