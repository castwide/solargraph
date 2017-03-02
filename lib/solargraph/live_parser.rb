# Solargraph Ruby Parser
# Copyright (c) 2015 by Fred Snyder for Castwide Technologies LLC
#
# Solargraph::Parser builds a code representation of existing Ruby interfaces
# for use in the Solargraph IDE.
#
# Example use:
#
#    parser = Solargraph::Parser.new
#    parser.parse            #=> String with the entire Ruby interface
#    parser.parse("Fixnum")  #=> String with the Fixnum interface
#require 'yard'
#require 'yard/registry'

module Solargraph
  class LiveParser
    def get_yard_return(path)
      objects = []
      yardocs = ['yard/2.2.0/.yardoc', 'ruby/yard/2.2.0/.yardoc-stdlib']
      yardocs.each { |y|
        YARD::Registry.load!(y)
        o = YARD::Registry.at(path)
        if !o.nil?
          objects.push o
        end
      }
      result = nil
      objects.each { |x|
        meth = x
        if !meth.tag(:return) and meth.tag(:overload) and meth.tag(:overload).tag(:return)
          meth = meth.tag(:overload)
        end
        meth.tags(:return).each { |r|
          result = "#{r.types[0]}"
          break
        }
        break if !result.nil?
      }
      result
    end
    def initialize

    end
    def parse namespace = nil
      #puts "Namespace: #{namespace}"
      @parsed = []
      code = ""
      fqns = namespace
      if fqns.nil?
        #code += parse("BasicObject")
        #code += parse("Object")
        #code += parse("Kernel")
        code += parse("Module")
        return code
      end
      mod = eval("#{fqns}")
      if !mod.nil?
        if mod.instance_of?(Class)
          #puts "Parsing class #{mod} to #{fqns}"
          code += parse_class mod, fqns
        elsif mod.instance_of?(Module)
          #puts "Parsing module #{mod} to #{fqns}"
          code += parse_module mod, fqns
        else
          #raise "I don't know what a #{fqns} is."
          code += "#{fqns} = nil\n"
        end
      else
        #puts "NIL!"
      end
      code
    end
    def self.parse n
      LiveParser.new.parse(n)
    end
    private
    def parse_class cls, rel_name
      return "" if @parsed.include?(cls)
      @parsed.push cls
      code = ""
      #code += "class #{rel_name}"
      code += "class #{cls}"
      if !cls.superclass.nil? && cls.superclass != cls
        code += " < #{cls.superclass}"
      end
      code += "\n"
      code += parse_class_internals(cls)
      code += "end\n"
      cls.constants().each { |c|
        #obj = cls.class_eval(c.to_s)
        begin
          obj = cls.const_get(c)
          if obj.kind_of?(Class)
            code += parse_class(obj, c)
          elsif obj.kind_of?(Module)
            code += parse_module(obj, c)
          else
            #code += subparse(obj)
          end
        #rescue NameError => e
        #  #puts "NOPE! NOT #{c}"
        #end
        rescue Exception => e
          # TODO: Ignoring all exceptions for now
        end
      }
      code
    end
    def parse_module mod, rel_name
      return "" if @parsed.include?(mod) or mod == Solargraph
      @parsed.push mod
      code = ""
      #if (mod.to_s != "Kernel")
        code = "module #{mod}\n"
      #end
      code += parse_module_internals(mod)
      #if (mod.to_s != "Kernel")
        code += "end\n"
      #end
      mod.constants().each { |c|
        #obj = mod.class_eval(c.to_s)
        begin
          obj = mod.const_get(c)
        rescue LoadError => e
          code += "# @todo Failed to load #{c} from #{mod}\n"
        end
        if obj.kind_of?(Class)
          code += parse_class(obj, c)
        elsif obj.kind_of?(Module)
          code += parse_module(obj, c)
        else
          #code += subparse(obj)
        end
      }
      code
    end
    def parse_class_internals obj
      code = ""
      obj.included_modules.each { |inc|
        #if (inc.to_s != "Kernel")
          code += "include #{inc}\n"
        #end
      }
      obj.public_methods(false).each { |m|
        if !can_ignore?(obj, m)
          args = build_args obj.method(m)
          #ret = get_yard_return "#{obj}::#{m}"
          #if !ret.nil?
          #   code += "# @return [#{ret}]\n"
          #end
          code += "def self.#{m}#{args};end\n"
        end
      }
      alloc = obj
      obj.singleton_methods(false).each { |m|
        if !can_ignore?(obj, m)
          args = build_args obj.method(m)
          #ret = get_yard_return "#{obj}::#{m}"
          #if !ret.nil?
          #   code += "# @return [#{ret}]\n"
          #end
          code += "def self.#{m}#{args};end\n"
        end
      }
      obj.public_instance_methods(false).each { |m|
        if !can_ignore?(obj, m)
          begin
            args = build_args obj.public_instance_method(m)
          rescue TypeError => e
            args = ""
          end
          #ret = get_yard_return "#{obj}##{m}"
          #if !ret.nil?
          #   code += "# @return [#{ret}]\n"
          #end
          code += "def #{m}#{args};end\n"
        end
      }
      code
    end
    def parse_module_internals obj
      code = ""
      obj.included_modules.each { |inc|
        #if (inc.to_s != "Kernel")
          code += "include #{inc}\n"
        #end
      }
      obj.public_methods(false).each { |m|
        if obj == Kernel #and obj.singleton_methods.include?(m)
          next
        end
        if !can_ignore?(obj, m)
          args = build_args obj.method(m)
          #ret = get_yard_return "#{obj}##{m}"
          #if !ret.nil?
          #   code += "# @return [#{ret}]\n"
          #end
          code += "def #{m}#{args};end\n"
        end
      }
      obj.singleton_methods(false).each { |m|
        if !can_ignore?(obj, m)
          args = build_args obj.method(m)
          #ret = get_yard_return "#{obj}::#{m}"
          #if !ret.nil?
          #   code += "# @return [#{ret}]\n"
          #end
          code += "def self.#{m}#{args};end\n"
        end
      }
      #obj.public_instance_methods(false).each { |m|
      obj.public_instance_methods(false).each { |m|
        #if !can_ignore?(obj, m)
          args = build_args obj.public_instance_method(m)
          #ret = get_yard_return "#{obj}##{m}"
          #if !ret.nil?
          #   code += "# @return [#{ret}]\n"
          #end
          code += "def #{m}#{args};end\n"
        #end
      }
      code
    end
    def can_ignore?(obj, sym)
      #return false
      basics = [Kernel, Module, Object, BasicObject]
      return false if basics.include?(obj)
      result = false
      basics.each { |b|
        if b.respond_to?(sym)
          result = true
          break
        end
      }
      return result
    end
    def build_args method
      args = ""
      if (method.arity == -1)
        args = "(*args)"
      else
        arr = []
        num = 0
        method.parameters.each { |p|
          n = p[1]
          if n.to_s == ""
           n = "arg#{num}"
          end
          if p[0] == :req
            arr.push "#{n}"
          elsif p[0] == :opt
            arr.push "#{n} = nil"
          elsif p[0] == :rest
            arr.push "*#{n}"
          elsif p[0] == :block
            arr.push "&#{n}"
          end
          num += 1
        }
        args = "(" + arr.join(", ") + ")"
      end
      args
    end
  end
end
