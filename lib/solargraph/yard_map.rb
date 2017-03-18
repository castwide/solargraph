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
      required.each { |r|
        gy = YARD::Registry.yardoc_file_for_gem(r)
        yardocs.push gy unless gy.nil?
      }
      yardocs.push File.join(Dir.home, '.solargraph', 'cache', '2.0.0', 'yardoc')
      #yardocs.push File.join(Dir.home, '.solargraph', 'cache', '2.0.0', 'yardoc-stdlib')
    end

    def yardocs
      @yardocs ||= []
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
        result.push Suggestion.new(c.to_s.split('::').last, kind: Suggestion::CLASS)
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

    def get_methods namespace, scope = ''
      meths = []
      yardocs.each { |y|
        yard = YARD::Registry.load! y
        unless yard.nil?
          ns = nil
          if scope == ''
            ns = yard.at(namespace)
          else
            ns = yard.resolve(P(scope), namespace)
          end
          unless ns.nil?
            ns.meths(scope: :class, visibility: [:public]).each { |m|
              n = m.to_s.split('.').last
              meths.push Suggestion.new("#{n}", kind: Suggestion::METHOD) if n.to_s.match(/^[a-z]/i)
            }
            if ns.kind_of?(YARD::CodeObjects::ClassObject) and namespace != 'Class'
              meths += get_instance_methods('Class')
            end
          end
        end
      }
      meths
    end

    def get_instance_methods namespace, scope = ''
      meths = []
      yardocs.each { |y|
        yard = YARD::Registry.load! y
        unless yard.nil?
          ns = nil
          if scope == ''
            ns = yard.at(namespace)
          else
            ns = yard.resolve(P(scope), namespace)
          end
          unless ns.nil?
            ns.meths(scope: :instance, visibility: [:public]).each { |m|
              n = m.to_s.split('#').last
              meths.push Suggestion.new("#{n}", kind: Suggestion::METHOD, documentation: m.docstring, code_object: m) if n.to_s.match(/^[a-z]/i) and !m.to_s.start_with?('Kernel#') and !m.docstring.to_s.include?(':nodoc:')
            }
            if ns.kind_of?(YARD::CodeObjects::ClassObject) and namespace != 'Object'
              meths += get_instance_methods('Object')
            end
          end
        end
      }
      meths
    end
  end

end
