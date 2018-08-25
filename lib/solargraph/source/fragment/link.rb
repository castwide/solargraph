module Solargraph
  class Source
    class Fragment
      class Link
        attr_reader :word

        def initialize word = '<void>'
          @word = word
        end

        # @param api_map [ApiMap]
        # @param context [ComplexType]
        # @param locals [Array<Solargraph::Pin::Base>]
        # @return [ComplexType]
        def resolve api_map, context, locals
          ComplexType::VOID
        end
      end
    end
  end
end
