module Solargraph
  class Source
    class Chain
      class Constant < Link
        def initialize word
          @word = word
        end

        # @param api_map [ApiMap]
        def resolve_pins api_map, context, locals
          api_map.get_constants('', context.named_context).select{|p| p.name == word}
        end
      end
    end
  end
end
