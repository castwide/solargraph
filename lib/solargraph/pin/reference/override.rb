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

        def self.from_comment name, comment
          new(nil, name, Solargraph::Source.parse_docstring(comment).to_docstring.tags)
        end
      end
    end
  end
end
