module Solargraph
  class Source
    class Chain
      class Link
        attr_reader :word

        def initialize word = '<undefined>'
          @word = word
        end

        def undefined?
          word == '<undefined>'
        end

        def constant?
          is_a?(Chain::Constant)
        end

        # @param api_map [ApiMap]
        # @param context [ComplexType]
        # @param locals [Array<Solargraph::Pin::Base>]
        # @return [Array<Solargraph::Pin::Base>]
        def resolve api_map, context, locals
          []
        end

        def == other
          self.class == other.class and word == other.word
        end
      end
    end
  end
end
