# frozen_string_literal: true

module Solargraph
  module Pin
    module YardPin
      class Constant < Pin::Constant
        include YardMixin

        def initialize code_object, closure = nil, spec = nil
          closure ||= Solargraph::Pin::Namespace.new(
            name: code_object.namespace.to_s,
            gates: [code_object.namespace.to_s]
          )
          super(
            location: object_location(code_object, spec),
            closure: closure,
            name: code_object.name.to_s,
            comments: code_object.docstring ? code_object.docstring.all.to_s : '',
            visibility: code_object.visibility
          )
        end
      end
    end
  end
end
