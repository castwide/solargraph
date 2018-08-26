module Solargraph
  class Source
    class Fragment
      class Link
        attr_reader :word

        def initialize word = '<undefined>'
          @word = word
        end

        # @param api_map [ApiMap]
        # @param context [ComplexType]
        # @param locals [Array<Solargraph::Pin::Base>]
        # @return [Array<Solargraph::Pin::Base>]
        def resolve_pins api_map, context, locals
          []
        end
      end
    end
  end
end
