require 'rubygems'
require 'parser/current'
require 'yard'

module Solargraph

  class YardMap
    def initialize required: [], workspace: nil
      unless workspace.nil?
        wsy = File.join(workspace, '.yardoc')
        yardocs.push wsy if File.exist?(wsy)
      end
      used = []
      required.each { |r|
        if workspace.nil? or !File.exist?(File.join workspace, 'lib', "#{r}.rb")
          g = r.split('/').first
          unless used.include?(g)
            used.push g
            gy = YARD::Registry.yardoc_file_for_gem(g)
            yardocs.push gy unless gy.nil?
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
    end

    def yardocs
      @yardocs ||= []
    end

    def search query
      found = []
      yardocs.each { |y|
        yard = YARD::Registry.load! y
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
        yard = YARD::Registry.load! y
        unless yard.nil?
          obj = yard.at query
          #found.push YARD::Templates::Engine.render(format: :html, object: obj) unless obj.nil?
          unless obj.nil?
            # HACK: Fix return tags in core documentation
            fix_return! obj if obj.kind_of?(YARD::CodeObjects::MethodObject) and y.include?('.solargraph')
            found.push obj
          end
        end
      }
      found
    end

    def get_constants namespace, scope = ''
      consts = []
      result = []
      yardocs.each { |y|
        yard = YARD::Registry.load! y
        unless yard.nil?
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
      result
    end

    def at signature
      yardocs.each { |y|
        yard = YARD::Registry.load! y
        unless yard.nil?
          obj = yard.at(signature)
          return obj unless obj.nil?
        end
      }
      nil
    end

    def resolve signature, scope
      yardocs.each { |y|
        yard = YARD::Registry.load! y
        unless yard.nil?
          obj = yard.resolve(P(scope), signature)
          return obj unless obj.nil?
        end
      }
      nil
    end

    def get_methods namespace, scope = '', visibility: [:public]
      meths = []
      yardocs.each { |y|
        yard = YARD::Registry.load! y
        unless yard.nil?
          ns = nil
          #if scope == ''
          #  ns = yard.at(namespace)
          #else
            ns = find_first_resolved_namespace(yard, namespace, scope)
          #end
          unless ns.nil? or !ns.kind_of?(YARD::CodeObjects::NamespaceObject)
            ns.meths(scope: :class, visibility: visibility).each { |m|
              # HACK: Fix return tags in core documentation
              fix_return! m if y.include?('.solargraph')
              n = m.to_s.split(/[\.#]/).last
              label = "#{n}"
              args = get_method_args(m)
              label += " #{args.join(', ')}" unless args.empty?
              meths.push Suggestion.new(label, insert: "#{n}", kind: Suggestion::METHOD, documentation: m.docstring, code_object: m, detail: "#{ns}", location: "#{m.file}:#{m.line}")
            }
            if ns.kind_of?(YARD::CodeObjects::ClassObject) and namespace != 'Class'
              meths += get_instance_methods('Class')
            end
          end
        end
      }
      meths
    end

    def get_instance_methods namespace, scope = '', visibility: [:public]
      meths = []
      yardocs.each { |y|
        yard = YARD::Registry.load! y
        unless yard.nil?
          ns = nil
          #if scope == ''
          #  ns = yard.at(namespace)
          #else
            ns = find_first_resolved_namespace(yard, namespace, scope)
          #end
          unless ns.nil?
            ns.meths(scope: :instance, visibility: visibility).each { |m|
              # HACK: Fix return tags in core documentation
              fix_return! m if y.include?('.solargraph')
              n = m.to_s.split(/[\.#]/).last
              if n.to_s.match(/^[a-z]/i) and (namespace == 'Kernel' or !m.to_s.start_with?('Kernel#')) and !m.docstring.to_s.include?(':nodoc:')
                label = "#{n}"
                args = get_method_args(m)
                label += " #{args.join(', ')}" unless args.empty?
                meths.push Suggestion.new(label, insert: "#{n}", kind: Suggestion::METHOD, documentation: m.docstring, code_object: m, detail: "#{ns}", location: "#{m.file}:#{m.line}")
              end
            }
            if ns.kind_of?(YARD::CodeObjects::ClassObject) and namespace != 'Object'
              meths += get_instance_methods('Object')
            end
          end
        end
      }
      meths
    end

    def gem_names
      Gem::Specification.map{ |s| s.name }.uniq
    end

    def find_fully_qualified_namespace namespace, scope
      yardocs.each { |y|
        yard = YARD::Registry.load! y
        unless yard.nil?
          obj = find_first_resolved_namespace(yard, namespace, scope)
          return obj.path unless obj.nil?
        end
      }
    end

    private

    def get_method_args meth
      args = []
      meth.parameters.each { |a|
        args.push a[0]
      }
      args
    end

    def fix_return! meth
      return unless meth.tag(:return).nil?
      return unless meth.docstring.all.include?('@return')
      text = ''
      meth.docstring.all.lines.each { |line|
        if line.strip.start_with?('@return')
          text += line.strip
        else
          text += line
        end
        text += "\n"
      }
      doc = YARD::Docstring.new(text, meth)
      meth.docstring = doc
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
  end

end
