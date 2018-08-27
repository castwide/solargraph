module Solargraph
  class Source
    class Chain
      class Constant < Link
        def initialize word
          @word = word
        end

        def resolve_pins api_map, context, locals
          ns = api_map.qualify(word, context.namespace)
          return [] if ns.nil?
          api_map.get_path_suggestions(ns)
        end
      end
    end
  end
end
