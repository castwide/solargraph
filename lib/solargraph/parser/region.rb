# frozen_string_literal: true

module Solargraph
  module Parser
    # Data used by the parser to track context at various locations in a
    # source.
    #
    class Region
      # Nearest enclosing Closure (method, block, or namespace). Kept as
      # its own field: it changes far less often than `compound_statement`.
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

      # Nearest enclosing CompoundStatement - a statement series where a
      # later one running implies the earlier ones did. Superset of
      # `closure`, adding branch bodies that are not scopes.
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
