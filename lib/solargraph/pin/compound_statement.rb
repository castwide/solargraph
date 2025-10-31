module Solargraph
  module Pin
    # A series of statements where if a given statement executes, /all
    # of the previous statements in the sequence must have executed as
    # well/.  In other words, the statements are run from the top in
    # sequence, until interrupted by something like a
    # return/break/next/raise/etc.
    #
    # This mix-in is used in flow sensitive typing to determine how
    # far we can assume a given assertion about a type can be trusted
    # to be true.
    #
    # Some examples in Ruby:
    #
    # * Bodies of methods and Ruby blocks
    # * Branches of conditionals and loops - if/elsif/else,
    #   unless/else, when, until, ||=, ?:, switch/case/else
    # * The body of begin-end/try/rescue/ensure statements
    #
    # Compare/contrast with:
    #
    # * Scope - a sequence where variables declared are not available
    #   after the end of the scope.  Note that this is not necessarily
    #   true for a compound statement.
    # * Compound statement - synonym
    # * Block - in Ruby this has a special meaning (a closure passed to a method), but
    #   in general parlance this is also a synonym.
    # * Closure - a sequence which is also a scope
    # * Namespace - a named sequence which is also a scope and a
    #   closure
    #
    # See:
    #   https://cse.buffalo.edu/~regan/cse305/RubyBNF.pdf
    #   https://ruby-doc.org/docs/ruby-doc-bundle/Manual/man-1.4/syntax.html
    #   https://en.wikipedia.org/wiki/Block_(programming)
    #
    # Note:
    #
    # Just because statement #1 in a sequence is executed, it doesn't
    # mean that future ones will.  Consider the effect of
    # break/next/return/raise/etc. on control flow.
    class CompoundStatement < Pin::Base
      attr_reader :node

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
