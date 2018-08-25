module Solargraph
  class Source
    class Fragment
      class Constant < Link
        def initialize word
          @word = word
        end

        def resolve api_map, context, locals
          # @complex_type.qualify(api_map, context.namespace)
          ns = api_map.qualify(word, context.namespace)
          return ComplexType::UNDEFINED if ns.nil?
          api_map.get_path_suggestions(ns).first.return_complex_type
        end
      end
    end
  end
end
