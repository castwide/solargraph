module Solargraph
  module Pin
    # Mix-in for pins which enclose code which the 'break' statement
    # works with-in - e.g., blocks, when, until, ...
    module Breakable
      include CompoundStatementable

      # @return [Parser::AST::Node]
      attr_reader :node
    end
  end
end
