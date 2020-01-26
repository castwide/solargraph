# frozen_string_literal: true

module Solargraph
  module Pin
    module YardPin
      class Namespace < Pin::Namespace
        include YardMixin

        def initialize code_object, spec, closure = nil
          # @code_object = code_object
          # @spec = spec
          closure ||= Solargraph::Pin::Namespace.new(
            name: code_object.namespace.to_s,
            closure: Pin::ROOT_PIN,
            gates: [code_object.namespace.to_s]
          )
          super(
            location: object_location(code_object, spec),
            name: code_object.name.to_s,
            comments: code_object.docstring ? code_object.docstring.all.to_s : '',
            type: code_object.is_a?(YARD::CodeObjects::ClassObject) ? :class : :module,
            visibility: code_object.visibility,
            closure: closure
          )
        end
      end
    end
  end
end
