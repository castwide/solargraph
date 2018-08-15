module Solargraph
  module Pin
    module YardPin
      class Constant < Pin::Constant
        include YardMixin

        def initialize code_object, location
          super(location, code_object.namespace.to_s, code_object.name.to_s, comments_from(code_object), nil, nil, nil, code_object.visibility)
        end
      end
    end
  end
end
map = Solargraph::ApiMap.new
