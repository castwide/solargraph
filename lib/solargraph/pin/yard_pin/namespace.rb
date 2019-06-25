# frozen_string_literal: true

module Solargraph
  module Pin
    module YardPin
      class Namespace < Pin::Namespace
        include YardMixin

        def initialize code_object, location
          @code_object = code_object
          closure = Solargraph::Pin::Namespace.new(
            name: code_object.namespace.to_s,
            closure: Pin::ROOT_PIN,
            gates: [code_object.namespace.to_s]
          )
          super(
            location: location,
            name: code_object.name.to_s,
            comments: nil,
            type: namespace_type(code_object),
            visibility: code_object.visibility,
            closure: closure,
            gates: split_to_gates(code_object.path)
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
