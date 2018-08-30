module Solargraph
  class Source
    class Chain
      class Constant < Link
        def initialize word
          @word = word
        end

        # @param api_map [ApiMap]
        def resolve_pins api_map, context, locals
          parts = word.split('::')
          last = parts.pop
          first = parts.join('::').to_s
          api_map.get_constants(first, context.named_context).select{|p| p.name == last}
        end
      end
    end
  end
end
