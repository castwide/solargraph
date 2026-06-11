# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class Array < Literal
        # @param children [::Array<Chain>]
        # @param node [Parser::AST::Node]
        def initialize children, node
          super('::Array', node)
          @children = children
        end

        def word
          @word ||= "<#{@type}>"
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [::Array<Pin::Parameter, Pin::LocalVariable>]
        def resolve api_map, name_pin, locals
          type = ComplexType::UniqueType.new('Array', rooted: true)
          [Pin::ProxyType.anonymous(type, source: :chain)]
        end
      end
    end
  end
end
