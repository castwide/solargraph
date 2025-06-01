# frozen_string_literal: true

module Solargraph
  module Pin
    class Until < Base
      include Breakable

      # @param receiver [Parser::AST::Node, nil]
      # @param node [Parser::AST::Node, nil]
      # @param context [ComplexType, nil]
      # @param args [::Array<Parameter>]
      def initialize node: nil, **splat
        super(**splat)
        @node = node
      end
    end
  end
end
