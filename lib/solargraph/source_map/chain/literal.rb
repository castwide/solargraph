module Solargraph
  class SourceMap
    class Chain
      class Literal < Link
        def word
          @word ||= "<#{@type}>"
        end

        # @param type [String]
        def initialize type
          @type = type
          @complex_type = ComplexType.parse(type).first
        end

        def resolve api_map, name_pin, locals
          [Pin::ProxyType.anonymous(@complex_type)]
        end
      end
    end
  end
end
