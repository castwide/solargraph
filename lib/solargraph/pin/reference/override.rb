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

        def self.method_return name, *tags
          new(nil, name, [YARD::Tags::Tag.new('return', nil, tags)])
        end
      end
    end
  end
end
