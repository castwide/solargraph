# frozen_string_literal: true

module Solargraph
  class YardMap
    class Mapper
      module ToNamespace
        extend YardMap::Helpers

        # @param code_object [YARD::CodeObjects::NamespaceObject]
        # @param spec [Gem::Specification, nil]
        # @param closure [Pin::Closure, nil]
        # @return [Pin::Namespace]
        def self.make code_object, spec, closure = nil
          closure ||= create_closure_namespace_for(code_object, spec)
          location = object_location(code_object, spec)

          Pin::Namespace.new(
            location: location,
            name: code_object.name.to_s,
            comments: code_object.docstring ? code_object.docstring.all.to_s : '',
            type: code_object.is_a?(YARD::CodeObjects::ClassObject) ? :class : :module,
            visibility: code_object.visibility,
            closure: closure,
            source: :yardoc,
          )
        end
      end
    end
  end
end
