module Solargraph
  module Pin
    class Reference
      class Override < Reference
        attr_reader :tags

        def initialize location, name, tags
          super(location: location, name: name)
          @tags = tags
        end

        def kind
          Pin::OVERRIDE_REFERENCE
        end
      end
    end
  end
end
