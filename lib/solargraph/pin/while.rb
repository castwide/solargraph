# frozen_string_literal: true

module Solargraph
  module Pin
    class While < CompoundStatement
      include Breakable

      # @param node [Parser::AST::Node, nil]
      def initialize node: nil, **splat
        super(**splat)
        @node = node
      end
    end
  end
end
