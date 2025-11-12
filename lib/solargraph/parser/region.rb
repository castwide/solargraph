# frozen_string_literal: true

module Solargraph
  module Parser
    # Data used by the parser to track context at various locations in a
    # source.
    #
    class Region
      # @return [Pin::Closure]
      attr_reader :closure

      attr_reader :binder

      # @return [Symbol]
      attr_reader :scope

      # @return [Symbol]
      attr_reader :visibility

      # @return [Solargraph::Source]
      attr_reader :source

      # @return [Array<Symbol>]
      attr_reader :lvars

      # @param source [Source]
      # @param closure [Pin::Closure, nil]
      # @param binder [ComplexType, ComplexType::UniqueType, nil]
      # @param scope [Symbol, nil]
      # @param visibility [Symbol]
      # @param lvars [Array<Symbol>]
      def initialize source: Solargraph::Source.load_string(''), closure: nil,
                     binder: nil, scope: nil, visibility: :public, lvars: []
        @source = source
        @closure = closure || Pin::Namespace.new(name: '', location: source.location, source: :parser)
        @binder = binder
        @scope = scope
        @visibility = visibility
        @lvars = lvars
      end

      # @return [String]
      def filename
        source.filename
      end

      # Generate a new Region with the provided attribute changes.
      #
      # @param closure [Pin::Closure, nil]
      # @param binder [ComplexType, ComplexType::UniqueType, nil]
      # @param scope [Symbol, nil]
      # @param visibility [Symbol, nil]
      # @param lvars [Array<Symbol>, nil]
      # @return [Region]
      def update closure: nil, binder: nil, scope: nil, visibility: nil, lvars: nil
        Region.new(
          source: source,
          closure: closure || self.closure,
          binder: binder || closure&.binder || self.closure.binder,
          scope: scope || self.scope,
          visibility: visibility || self.visibility,
          lvars: lvars || self.lvars
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
