# frozen_string_literal: true

module Solargraph
  module Pin
    module YardPin
      class Constant < Pin::Constant
        include YardMixin

        def initialize code_object, closure = nil, spec = nil
          # @code_object = code_object
          # @spec = spec
          @location = object_location(code_object, spec)
          @comments ||= code_object.docstring ? code_object.docstring.all.to_s : ''
          closure ||= Solargraph::Pin::Namespace.new(
            name: code_object.namespace.to_s,
            gates: [code_object.namespace.to_s]
          )
          super(
            location: location,
            closure: closure,
            name: code_object.name.to_s,
            comments: nil,
            visibility: code_object.visibility
          )
        end
      end
    end
  end
end
