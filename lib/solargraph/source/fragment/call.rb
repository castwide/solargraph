module Solargraph
  class Source
    class Fragment
      class Call < Link
        # @return [String]
        attr_reader :word

        # @return [Array<Chain>]
        attr_reader :arguments

        def initialize word, arguments = []
          @word = word
          @arguments = arguments
        end

        def resolve_pins api_map, context, locals
          return ComplexType.parse(context.namespace).first if word == 'new' and context.scope == :class
          found = locals.select{|p| p.name == word}
          return found unless found.empty?
          api_map.get_method_stack(context.namespace, word, scope: context.scope)
        end
      end
    end
  end
end
