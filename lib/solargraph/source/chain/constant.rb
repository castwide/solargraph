module Solargraph
  class Source
    class Chain
      class Constant < Link
        def initialize word
          @word = word
        end

        def resolve api_map, name_pin, locals
          return [Pin::ROOT_PIN] if word.empty?
          parts = word.split('::')
          last = parts.pop
          context = (name_pin.context.namespace.split('::') + parts).join('::')
          api_map.get_constants(context).select{|p| p.name == last}
        end
      end
    end
  end
end
