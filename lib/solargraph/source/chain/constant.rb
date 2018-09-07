module Solargraph
  class Source
    class Chain
      class Constant < Link
        def initialize word
          @word = word
        end

        def resolve api_map, name_pin, locals
          parts = word.split('::')
          last = parts.pop
          first = parts.join('::').to_s
          api_map.get_constants(first, name_pin.context.namespace).select{|p| p.name == last}
        end
      end
    end
  end
end
