module Solargraph
  module Pin
    module YardPin
      class Namespace < Pin::Namespace
        include YardMixin

        def initialize code_object, location
          # super(location, code_object.namespace.to_s, code_object.name.to_s, comments_from(code_object), namespace_type(code_object), code_object.visibility)
          closure = Solargraph::Pin::Namespace.new(
            name: code_object.namespace.to_s,
            closure: Pin::ROOT_PIN
          )
          super(
            location: location,
            name: code_object.name.to_s,
            comments: comments_from(code_object),
            type: namespace_type(code_object),
            visibility: code_object.visibility,
            closure: closure
          )
        end

        private

        def namespace_type code_object
          code_object.is_a?(YARD::CodeObjects::ClassObject) ? :class : :module
        end
      end
    end
  end
end
