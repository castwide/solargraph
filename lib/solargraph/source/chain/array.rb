module Solargraph
  class Source
    class Chain
      class Array < Literal
        # @param children [::Array<Chain>]
        def initialize children
          super('::Array')
          @children = children
        end

        def word
          @word ||= "<#{@type}>"
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [Enumerable<Pin::LocalVariable>]
        def resolve api_map, name_pin, locals
          child_types = @children.map do |child|
            child.infer(api_map, name_pin, locals)
          end
          type = if child_types.length == 0 || child_types.any?(&:undefined?)
                   "::Array"
                 elsif child_types.uniq.length == 1
                   "::Array<#{child_types.first.to_s}>"
                 else
                   "::Array(#{child_types.map(&:to_s).join(', ')})"
                 end
          [Pin::ProxyType.anonymous(ComplexType.try_parse(type))]
        end
      end
    end
  end
end
