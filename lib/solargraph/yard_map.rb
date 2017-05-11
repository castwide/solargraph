require 'rubygems'
require 'parser/current'
require 'yard'

module Solargraph

  class YardMap
    autoload :Cache, 'solargraph/yard_map/cache'

    def initialize required: [], workspace: nil
      unless workspace.nil?
        wsy = File.join(workspace, '.yardoc')
        yardocs.push wsy if File.exist?(wsy)
        #wsy = Dir[File.join workspace, '**/*.rb']
        #yardocs.push(wsy)
      end
      used = []
      required.each { |r|
        if workspace.nil? or !File.exist?(File.join workspace, 'lib', "#{r}.rb")
          g = r.split('/').first
          unless used.include?(g)
            used.push g
            gy = YARD::Registry.yardoc_file_for_gem(g)
            if gy.nil?
              STDERR.puts "Required path not found: #{r}"
            else
              yardocs.push gy
            end
          end
        end
      }
      # TODO: Experimental loading of all gems
      #Bundler.load.specs.each { |s|
      #  unless used.include?(s.name)
      #    used.push s.name
      #    gy = YARD::Registry.yardoc_file_for_gem(s.name)
      #    yardocs.push gy unless gy.nil?
      #  end
      #}
      yardocs.push File.join(Dir.home, '.solargraph', 'cache', '2.0.0', 'yardoc')
      #yardocs.push File.join(Dir.home, '.solargraph', 'cache', '2.0.0', 'yardoc-stdlib')
      yardocs.uniq!
      cache_core
    end

    def yardocs
      @yardocs ||= []
    end

    def load_yardoc y
      if y.kind_of?(Array)
        YARD::Registry.load y, true
      else
        YARD::Registry.load! y
      end
    end

    def search query
      found = []
      yardocs.each { |y|
        yard = load_yardoc(y)
        unless yard.nil?
          yard.paths.each { |p|
            found.push p if p.downcase.include?(query.downcase)
          }
        end
      }
      found.sort
    end

    def document query
      found = []
      yardocs.each { |y|
        yard = load_yardoc(y)
        unless yard.nil?
          obj = yard.at query
          found.push obj unless obj.nil?
        end
      }
      found
    end

    # @return [Array<Suggestion>]
    def get_constants namespace, scope = ''
      cached = cache.get_constants(namespace, scope)
      return cached unless cached.nil?
      consts = []
      binds = []
      result = []
      yardocs.each { |y|
        yard = load_yardoc(y)
        unless yard.nil?
          if namespace == '' and scope == ''
            # Check for a bind tag in the yardoc root. If it exists, treat
            # workspace code as a DSL that uses public instance methods in the
            # specified namespaces.
            b = yard.root.tag(:bind)
            unless b.nil?
              binds.concat b.types
            end
          end
          ns = nil
          if scope == ''
            ns = yard.at(namespace)
          else
            ns = yard.resolve(P(scope), namespace)
          end
          consts += ns.children unless ns.nil?
        end
      }
      consts.each { |c|
        detail = nil
        kind = nil
        if c.kind_of?(YARD::CodeObjects::ClassObject)
          detail = 'Class'
          kind = Suggestion::CLASS
        elsif c.kind_of?(YARD::CodeObjects::ModuleObject)
          detail = 'Module'
          kind = Suggestion::MODULE
        end
        result.push Suggestion.new(c.to_s.split('::').last, detail: detail, kind: kind)
      }
      binds.each { |type|
        result.concat get_instance_methods(type, '', visibility: [:public])
      }
      cache.set_constants(namespace, scope, result)
      result
    end

    def at signature
      yardocs.each { |y|
        yard = load_yardoc(y)
        unless yard.nil?
          obj = yard.at(signature)
          return obj unless obj.nil?
        end
      }
      nil
    end

    def resolve signature, scope
      yardocs.each { |y|
        yard = load_yardoc(y)
        unless yard.nil?
          obj = yard.resolve(P(scope), signature)
          return obj unless obj.nil?
        end
      }
      nil
    end

    # @return [Array<Suggestion>]
    def get_methods namespace, scope = '', visibility: [:public]
      cached = cache.get_methods(namespace, scope, visibility)
      return cached unless cached.nil?
      meths = []
      binds = []
      yardocs.each { |y|
        yard = load_yardoc(y)
        unless yard.nil?
          ns = nil
          ns = find_first_resolved_namespace(yard, namespace, scope)
          b = yard.root.tag(:bind)
          binds.concat b.types unless b.nil?
          unless ns.nil?
            ns.meths(scope: :class, visibility: visibility).each { |m|
              n = m.to_s.split(/[\.#]/).last.gsub(/=/, ' = ')
              label = "#{n}"
              args = get_method_args(m)
              label += " #{args.join(', ')}" unless args.empty?
              meths.push Suggestion.new(label, insert: "#{n.gsub(/=/, ' = ')}", kind: Suggestion::METHOD, documentation: m.docstring, code_object: m, detail: "#{ns}", location: "#{m.file}:#{m.line}")
            }
            # Collect superclass methods
            if ns.kind_of?(YARD::CodeObjects::ClassObject) and !ns.superclass.nil?
              meths += get_methods ns.superclass.to_s, '', visibility: [:public, :protected] unless ['Object', 'BasicObject', ''].include?(ns.superclass.to_s)
            end
            if ns.kind_of?(YARD::CodeObjects::ClassObject) and namespace != 'Class'
              meths += get_instance_methods('Class')
            end
          end
        end
      }
      binds.each { |b|
        meths += get_instance_methods(b, scope, visibility: [:public])
      }
      cache.set_methods(namespace, scope, visibility, meths)
      meths
    end

    # @return [Array<Suggestion>]
    def get_instance_methods namespace, scope = '', visibility: [:public]
      cached = cache.get_instance_methods(namespace, scope, visibility)
      return cached unless cached.nil?
      meths = []
      yardocs.each { |y|
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
                label += " #{args.join(', ')}" unless args.empty?
                meths.push Suggestion.new(label, insert: "#{n.gsub(/=/, ' = ')}", kind: Suggestion::METHOD, documentation: m.docstring, code_object: m, detail: "#{ns}", location: "#{m.file}:#{m.line}")
              end
            }
            if ns.kind_of?(YARD::CodeObjects::ClassObject) and namespace != 'Object'
              if ns.superclass.kind_of?(YARD::CodeObjects::Proxy)
                meths += get_instance_methods(ns.superclass.to_s)
              end
            end
          end
        end
      }
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
      parts = scope.split('::')
      while parts.length > 0
        ns = yard.resolve(P(parts.join('::')), namespace, true)
        return ns unless ns.nil?
        parts.pop
      end
      yard.at(namespace)
    end

    def cache_core
      c = get_constants '', ''
      c.each { |n|
        get_methods 'n', visibility: :public
        get_instance_methods 'n', visibility: :public
      }
    end
  end

end
