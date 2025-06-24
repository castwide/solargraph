# frozen_string_literal: true

module Solargraph
  module Pin
    class Reference
      class Override < Reference
        # @return [::Array<YARD::Tags::Tag>]
        attr_reader :tags

        # @return [::Array<Symbol>]
        attr_reader :delete

        def closure
          nil
        end

        def initialize location, name, tags, delete = [], **splat
          super(location: location, name: name, **splat)
          @tags = tags
          @delete = delete
        end

        def self.method_return name, *tags, delete: [], **splat
          new(nil, name, [YARD::Tags::Tag.new('return', nil, tags)], delete, **splat)
        end

        def self.from_comment name, comment, **splat
          new(nil, name, Solargraph::Source.parse_docstring(comment).to_docstring.tags, **splat)
        end
      end
    end
  end
end
