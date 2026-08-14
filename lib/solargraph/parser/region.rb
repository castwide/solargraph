# frozen_string_literal: true

module Solargraph
  module Parser
    # Data used by the parser to track context at various locations in a
    # source.
    #
    class Region
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

      # True if the current position may be skipped, or run zero or
      # multiple times, at runtime - e.g. inside an if/while/until/
      # rescue/&&/||/||= body, or inside a block body (which, despite
      # its Block pin being a Closure like Method/Namespace, may run
      # zero or many times depending on the method it's passed to,
      # unlike a method/namespace body which always runs exactly once
      # when reached). Not derivable from `compound_statement.is_a?
      # (Closure)` alone for that reason - Block is the case where
      # "is a Closure" and "unconditionally executes" diverge.
      #
      # @return [Boolean]
      attr_reader :conditional

      # @param source [Source]
      # @param closure [Pin::Closure, nil]
      # @param scope [Symbol, nil]
      # @param visibility [Symbol]
      # @param lvars [Array<Symbol>]
      # @param compound_statement [Pin::CompoundStatement, nil]
      # @param conditional [Boolean]
      def initialize source: Solargraph::Source.load_string(''), closure: nil,
                     scope: nil, visibility: :public, lvars: [],
                     compound_statement: nil, conditional: false
        @source = source
        @closure = closure || Pin::Namespace.new(name: '', location: source.location, source: :parser)
        @compound_statement = compound_statement || @closure
        @scope = scope
        @visibility = visibility
        @lvars = lvars
        @conditional = conditional
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
      # @param conditional [Boolean, nil]
      # @return [Region]
      def update closure: nil, scope: nil, visibility: nil, lvars: nil,
                 compound_statement: nil, conditional: nil
        Region.new(
          source: source,
          closure: closure || self.closure,
          scope: scope || self.scope,
          visibility: visibility || self.visibility,
          lvars: lvars || self.lvars,
          compound_statement: compound_statement || self.compound_statement,
          conditional: conditional.nil? ? self.conditional : conditional
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
