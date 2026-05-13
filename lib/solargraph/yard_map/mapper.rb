# frozen_string_literal: true

module Solargraph
  class YardMap
    class Mapper
      autoload :ToMethod, 'solargraph/yard_map/mapper/to_method'
      autoload :ToNamespace, 'solargraph/yard_map/mapper/to_namespace'
      autoload :ToConstant, 'solargraph/yard_map/mapper/to_constant'

      # @param code_objects [Array<YARD::CodeObjects::Base>]
      # @param spec [Gem::Specification, nil]
      def initialize code_objects, spec = nil
        @code_objects = code_objects
        @macro_code_objects = code_objects.select { |co| co.is_a?(YARD::CodeObjects::MacroObject) }
        @spec = spec
        # @type [Array<Solargraph::Pin::Base>]
        @pins = []
        @namespace_pins = {}
      end

      # @return [Array<Pin::Base>]
      def map
        @code_objects.each do |co|
          @pins.concat generate_pins co
        end
        # Some yardocs contain documentation for dependencies that can be
        # ignored here. The YardMap will load dependencies separately.
        # @sg-ignore Need to add nil check here
        @pins.keep_if { |pin| pin.location.nil? || File.file?(pin.location.filename) } if @spec
        @pins
      end

      private

      # @param code_object [YARD::CodeObjects::Base]
      # @return [Array<Pin::Base>]
      def generate_pins code_object
        result = []
        case code_object
        when YARD::CodeObjects::NamespaceObject
          nspin = ToNamespace.make(code_object, @spec, @namespace_pins[code_object.namespace.to_s])
          @namespace_pins[code_object.path] = nspin
          result.push nspin
          if code_object.is_a?(YARD::CodeObjects::ClassObject) && !code_object.superclass.nil?
            # This method of superclass detection is a bit of a hack. If
            # the superclass is a Proxy, it is assumed to be undefined in its
            # yardoc and converted to a fully qualified namespace.
            superclass = if code_object.superclass.is_a?(YARD::CodeObjects::Proxy)
                           "::#{code_object.superclass}"
                         else
                           code_object.superclass.to_s
                         end
            result.push Solargraph::Pin::Reference::Superclass.new(name: superclass, closure: nspin, source: :yard_map)
          end
          # @sg-ignore flow sensitive typing ought to be able to handle 'when ClassName'
          code_object.class_mixins.each do |m|
            result.push Solargraph::Pin::Reference::Extend.new(closure: nspin, name: m.path, source: :yard_map)
          end
          # @sg-ignore flow sensitive typing ought to be able to handle 'when ClassName'
          code_object.instance_mixins.each do |m|
            result.push Solargraph::Pin::Reference::Include.new(
              closure: nspin, # @todo Fix this
              name: m.path,
              source: :yard_map
            )
          end
        when YARD::CodeObjects::MethodObject
          closure = @namespace_pins[code_object.namespace.to_s]
          macros = macros_for_method_object(code_object)
          # @sg-ignore flow sensitive typing ought to be able to handle 'when ClassName'
          if code_object.name == :initialize && code_object.scope == :instance
            # @todo Check the visibility of <Class>.new
            result.push ToMethod.make(code_object, 'new', :class, :public, closure, @spec)
            result.push ToMethod.make(code_object, 'initialize', :instance, :private, closure, @spec)
          else
            result.push ToMethod.make(code_object, nil, nil, nil, closure, @spec)
          end
        when YARD::CodeObjects::ConstantObject
          closure = @namespace_pins[code_object.namespace]
          result.push ToConstant.make(code_object, closure, @spec)
        end
        result
      end

      # @return [Array<YARD::CodeObjects::MacroObject>]
      def attached_macros
        @attached_macros ||= @macro_code_objects.select(&:attached?)
      end

      # @return [Hash{YARD::CodeObjects::MethodObject => YARD::CodeObjects::MacroObject}]
      def attached_macros_by_method_object
        @attached_macros_by_method_object ||= attached_macros.group_by(&:method_object)
      end

      # @param method_object [YARD::CodeObjects::MethodObject]
      # @return [Array<YARD::CodeObjects::MacroObject>]
      def macros_for_method_object(method_object)
        attached_macros_by_method_object[method_object]
      end
    end
  end
end
