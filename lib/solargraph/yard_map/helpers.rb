module Solargraph
  class YardMap
    module Helpers
      module_function

      # @param code_object [YARD::CodeObjects::Base]
      # @param spec [Gem::Specification, nil]
      # @return [Solargraph::Location, nil]
      def object_location code_object, spec
        if spec.nil? || code_object.nil? || code_object.file.nil? || code_object.line.nil?
          if code_object.namespace.is_a?(YARD::CodeObjects::NamespaceObject)
            # If the code object is a namespace, use the namespace's location
            return object_location(code_object.namespace, spec)
          end
          return Solargraph::Location.new(__FILE__, Solargraph::Range.from_to(__LINE__ - 1, 0, __LINE__ - 1, 0))
        end
        file = File.join(spec.full_gem_path, code_object.file)
        Solargraph::Location.new(file, Solargraph::Range.from_to(code_object.line - 1, 0, code_object.line - 1, 0))
      end

      # @param code_object [YARD::CodeObjects::Base]
      # @param spec [Gem::Specification, nil]
      # @return [Solargraph::Pin::Namespace]
      def create_closure_namespace_for(code_object, spec)
        code_object_for_location = code_object
        # code_object.namespace is sometimes a YARD proxy object pointing to a method path ("Object#new")
        code_object_for_location = code_object.namespace if code_object.namespace.is_a?(YARD::CodeObjects::NamespaceObject)
        namespace_location = object_location(code_object_for_location, spec)
        ns_name = code_object.namespace.to_s
        if ns_name.empty?
          Solargraph::Pin::ROOT_PIN
        else
          Solargraph::Pin::Namespace.new(
            name: ns_name,
            closure: Pin::ROOT_PIN,
            gates: [code_object.namespace.to_s],
            source: :yardoc,
            location: namespace_location
          )
        end
      end
    end
  end
end
