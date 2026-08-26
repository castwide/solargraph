# frozen_string_literal: true

module Solargraph
  module Parser
    # Data used by the parser to track context at various locations in a
    # source.
    #
    class Region
      # The nearest enclosing Closure pin (a method, block, or
      # namespace). Every pin needs this at construction time, so it
      # is tracked directly here rather than derived by walking
      # `compound_statement` up to its nearest Closure ancestor on
      # every pin push - that walk is `Pin::Base#closure`'s fallback
      # for a pin built with no `@closure` of its own, not the normal
      # path. `closure` only changes at a def/class/module/block
      # boundary; `compound_statement` changes at every conditional
      # branch, which is far more often - keeping them as two fields
      # updated at their own rates avoids re-walking a chain that is
      # usually unchanged since the last pin.
      #
      # @return [Pin::Closure]
      attr_reader :closure

      # @return [Symbol]
      attr_reader :scope

      # @return [Symbol]
      attr_reader :visibility

      # @return [Solargraph::Source]
      attr_reader :source

      # @return [Array<Symbol>]
      attr_reader :lvars

      # The nearest enclosing CompoundStatement pin (an if/when/while/
      # rescue/&&/||/||= body, a method/block body, or a namespace
      # body) - a series of statements/expressions where a later one
      # executing implies the earlier ones in the same series
      # executed too. Every Closure is also a CompoundStatement, so
      # this is a superset of the `closure` chain: it additionally
      # includes branch bodies that aren't scopes.
      #
      # @return [Pin::CompoundStatement]
      attr_reader :compound_statement

      # @param source [Source]
      # @param closure [Pin::Closure, nil]
      # @param scope [Symbol, nil]
      # @param visibility [Symbol]
      # @param lvars [Array<Symbol>]
      # @param compound_statement [Pin::CompoundStatement, nil]
      def initialize source: Solargraph::Source.load_string(''), closure: nil,
                     scope: nil, visibility: :public, lvars: [],
                     compound_statement: nil
        @source = source
        @closure = closure || Pin::Namespace.new(name: '', location: source.location, source: :parser)
        @compound_statement = compound_statement || @closure
        @scope = scope
        @visibility = visibility
        @lvars = lvars
      end

      # @return [String, nil]
      def filename
        source.filename
      end

      # @return [Pin::Namespace, nil]
      def namespace_pin
        ns = closure
        # @sg-ignore flow sensitive typing needs to handle while
        ns = ns.closure while ns && !ns.is_a?(Pin::Namespace)
        ns
      end

      # Generate a new Region with the provided attribute changes.
      #
      # @param closure [Pin::Closure, nil]
      # @param scope [Symbol, nil]
      # @param visibility [Symbol, nil]
      # @param lvars [Array<Symbol>, nil]
      # @param compound_statement [Pin::CompoundStatement, nil]
      # @return [Region]
      def update closure: nil, scope: nil, visibility: nil, lvars: nil,
                 compound_statement: nil
        Region.new(
          source: source,
          closure: closure || self.closure,
          scope: scope || self.scope,
          visibility: visibility || self.visibility,
          lvars: lvars || self.lvars,
          compound_statement: compound_statement || self.compound_statement
        )
      end

      # @param node [Parser::AST::Node]
      # @return [String]
      def code_for node
        source.code_for(node)
      end
    end
  end
end
