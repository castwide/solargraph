# frozen_string_literal: true

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

      # The immediately enclosing CompoundStatement, if any - nil only
      # for the synthetic root Namespace Region creates for top-level
      # code. Since Closure < CompoundStatement, walking this chain
      # until an ancestor is_a?(Closure) is how Base#closure is
      # derived when a pin has no directly-assigned @closure.
      #
      # @return [Pin::CompoundStatement, nil]
      attr_reader :compound_statement

      # True if this construct's body may be skipped, or run zero or
      # multiple times, at runtime - e.g. an if/while/until/rescue/&&/
      # ||/||= body, or a block body (which, despite being a Closure
      # like Method/Namespace, may run zero or many times depending on
      # the method it's passed to, unlike a method/namespace body,
      # which always runs exactly once when reached). Defaults false -
      # true only where a node processor explicitly marks a construct
      # as conditionally executed.
      #
      # @return [Boolean]
      attr_reader :conditional

      # @param node [Parser::AST::Node, nil]
      # @param compound_statement [Pin::CompoundStatement, nil]
      # @param conditional [Boolean]
      # @param [Hash{Symbol => Object}] splat
      def initialize node: nil, compound_statement: nil, conditional: false, **splat
        super(**splat)
        @node = node
        @compound_statement = compound_statement
        @conditional = conditional
      end

      # @param other [self]
      # @param attrs [Hash{Symbol => Object}]
      # @return [self]
      def combine_with other, attrs = {}
        new_attrs = {
          compound_statement: combine_compound_statement(other),
          conditional: choose(other, :conditional)
        }.merge(attrs)
        super(other, new_attrs)
      end

      # Bare CompoundStatement pins (if/when/rescue/&&/||/||= bodies)
      # all share name == '', so the same-name-assertion in
      # Base#choose_pin_attr_with_same_name (used by #combine_closure)
      # would be meaningless noise here - pick by location instead,
      # mirroring BaseVariable#combine_closure.
      #
      # @param other [self]
      # @return [Pin::CompoundStatement, nil]
      def combine_compound_statement other
        return compound_statement if compound_statement == other.compound_statement
        return compound_statement || other.compound_statement if compound_statement.nil? || other.compound_statement.nil?

        # @sg-ignore flow sensitive typing needs to handle attrs
        if compound_statement.location.nil? || other.compound_statement.location.nil?
          # @sg-ignore flow sensitive typing needs to handle attrs
          return compound_statement.location.nil? ? other.compound_statement : compound_statement
        end

        # @sg-ignore flow sensitive typing needs to handle attrs
        return compound_statement if compound_statement.location <= other.compound_statement.location

        other.compound_statement
      end
    end
  end
end
