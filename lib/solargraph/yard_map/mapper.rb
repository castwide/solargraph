module Solargraph
  class YardMap
    class Mapper
      def initialize code_objects, spec = nil
        @code_objects = code_objects
        @spec = spec
        @pins = []
        @namespace_pins = {}
      end

      def map
        @code_objects.each do |co|
          @pins.concat generate_pins co
        end
        @pins
      end

      def generate_pins code_object
        result = []
        location = object_location(code_object, @spec)
        if code_object.is_a?(YARD::CodeObjects::NamespaceObject)
          nspin = Solargraph::Pin::YardPin::Namespace.new(code_object, location)
          @namespace_pins[code_object.path] = nspin
          result.push nspin
          if code_object.is_a?(YARD::CodeObjects::ClassObject) and !code_object.superclass.nil?
            # @todo This method of superclass detection is a bit of a hack. If
            #   the superclass is a Proxy, it is assumed to be undefined in its
            #   yardoc and converted to a fully qualified namespace.
            if code_object.superclass.is_a?(YARD::CodeObjects::Proxy)
              superclass = "::#{code_object.superclass}"
            else
              superclass = code_object.superclass.to_s
            end
            # result.push Solargraph::Pin::Reference::Superclass.new(location, code_object.path, superclass) # @todo Finish this
            result.push Solargraph::Pin::Reference::Superclass.new(location: location, name: superclass, closure: nspin)
          end
          code_object.class_mixins.each do |m|
            # result.push Solargraph::Pin::Reference::Extend.new(location, code_object.path, m.path)
            result.push Solargraph::Pin::Reference::Extend.new(location: location, closure: nspin, name: m.path) # @todo Fix closure
          end
          code_object.instance_mixins.each do |m|
            # result.push Solargraph::Pin::Reference::Include.new(location, code_object.path, m.path)
            result.push Solargraph::Pin::Reference::Include.new(
              location: location,
              closure: nspin, # @todo Fix this
              name: m.path
            )
          end
        elsif code_object.is_a?(YARD::CodeObjects::MethodObject)
          closure = @namespace_pins[code_object.namespace.to_s]
          if code_object.name == :initialize && code_object.scope == :instance
            # @todo Check the visibility of <Class>.new
            result.push Solargraph::Pin::YardPin::Method.new(code_object, location, 'new', :class, :public, closure)
            result.push Solargraph::Pin::YardPin::Method.new(code_object, location, 'initialize', :instance, :private, closure)
          else
            result.push Solargraph::Pin::YardPin::Method.new(code_object, location, nil, nil, nil, closure)
          end
        elsif code_object.is_a?(YARD::CodeObjects::ConstantObject)
          closure = @namespace_pins[code_object.namespace]
          result.push Solargraph::Pin::YardPin::Constant.new(code_object, location, closure)
        end
        result  
      end

      # @param obj [YARD::CodeObjects::Base]
      # @return [Solargraph::Location]
      def object_location obj, spec = nil
        @object_file_cache ||= {}
        return nil if spec.nil? || obj.file.nil? || obj.line.nil?
        file = nil
        if @object_file_cache.key?(obj.file)
          file = @object_file_cache[obj.file]
        else
          tmp = File.join(spec.full_gem_path, obj.file)
          file = tmp if File.exist?(tmp)
          @object_file_cache[obj.file] = file
        end
        return nil if file.nil?
        Solargraph::Location.new(file, Solargraph::Range.from_to(obj.line - 1, 0, obj.line - 1, 0))
      end
    end
  end
end
