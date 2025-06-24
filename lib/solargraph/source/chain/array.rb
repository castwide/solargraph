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
          child_types = @children.map do |child|
            child.infer(api_map, name_pin, locals).simplify_literals
          end
          type = if child_types.length == 0 || child_types.any?(&:undefined?)
                   ComplexType::UniqueType.new('Array', rooted: true)
                 elsif child_types.uniq.length == 1 && child_types.first.defined?
                   ComplexType::UniqueType.new('Array', [], child_types.uniq, rooted: true, parameters_type: :list)
                 elsif child_types.length == 0
                   ComplexType::UniqueType.new('Array', rooted: true, parameters_type: :list)
                 else
                   ComplexType::UniqueType.new('Array', [], child_types, rooted: true, parameters_type: :fixed)
                 end
          [Pin::ProxyType.anonymous(type, source: :chain)]
        end
      end
    end
  end
end
