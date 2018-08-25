module Solargraph
  class Source
    class Fragment
      class Literal < Link
        def word
          @word ||= "<#{@type}>"
        end

        def initialize type
          @type = type
          @complex_type = ComplexType.parse(type).first
        end

        def resolve api_map, context, locals
          @complex_type.qualify(api_map, '')
        end
      end
    end
  end
end
