# frozen_string_literal: true

module Solargraph
  class YardMap
    class Mapper
      # @param code_objects [Array<YARD::CodeObjects::Base>]
      # @param spec [Gem::Specification]
      def initialize code_objects, spec = nil
        @code_objects = code_objects
        @spec = spec
        @pins = []
        @namespace_pins = {}
      end

      # @return [Array<Pin::Base>]
      def map
        @code_objects.each do |co|
          @pins.concat generate_pins co
        end
        @pins
      end

      # @param code_object [YARD::CodeObjects::Base]
      # @return [Array<Pin::Base>]
      def generate_pins code_object
        result = []
        if code_object.is_a?(YARD::CodeObjects::NamespaceObject)
          nspin = Solargraph::Pin::YardPin::Namespace.new(code_object, @spec, @namespace_pins[code_object.namespace.to_s])
          @namespace_pins[code_object.path] = nspin
          result.push nspin
          if code_object.is_a?(YARD::CodeObjects::ClassObject) and !code_object.superclass.nil?
            # This method of superclass detection is a bit of a hack. If
            # the superclass is a Proxy, it is assumed to be undefined in its
            # yardoc and converted to a fully qualified namespace.
            if code_object.superclass.is_a?(YARD::CodeObjects::Proxy)
              superclass = "::#{code_object.superclass}"
            else
              superclass = code_object.superclass.to_s
            end
            result.push Solargraph::Pin::Reference::Superclass.new(name: superclass, closure: nspin)
          end
          code_object.class_mixins.each do |m|
            result.push Solargraph::Pin::Reference::Extend.new(closure: nspin, name: m.path)
          end
          code_object.instance_mixins.each do |m|
            result.push Solargraph::Pin::Reference::Include.new(
              closure: nspin, # @todo Fix this
              name: m.path
            )
          end
        elsif code_object.is_a?(YARD::CodeObjects::MethodObject)
          closure = @namespace_pins[code_object.namespace.to_s]
          if code_object.name == :initialize && code_object.scope == :instance
            # @todo Check the visibility of <Class>.new
            result.push Solargraph::Pin::YardPin::Method.new(code_object, 'new', :class, :public, closure, @spec)
            result.push Solargraph::Pin::YardPin::Method.new(code_object, 'initialize', :instance, :private, closure, @spec)
          else
            result.push Solargraph::Pin::YardPin::Method.new(code_object, nil, nil, nil, closure, @spec)
          end
        elsif code_object.is_a?(YARD::CodeObjects::ConstantObject)
          closure = @namespace_pins[code_object.namespace]
          result.push Solargraph::Pin::YardPin::Constant.new(code_object, closure, @spec)
        end
        result
      end
    end
  end
end
