# frozen_string_literal: true

module Solargraph
  module Pin
    module YardPin
      class Constant < Pin::Constant
        include YardMixin

        def initialize code_object, location, closure = nil
          @code_object = code_object
          closure ||= Solargraph::Pin::Namespace.new(
            name: code_object.namespace.to_s
          )
          super(
            location: location,
            closure: closure,
            name: code_object.name.to_s,
            comments: comments_from(code_object),
            visibility: code_object.visibility
          )
        end
      end
    end
  end
end
