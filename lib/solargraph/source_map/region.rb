module Solargraph
  class SourceMap
    # Data used by the NodeProcessor library to track context at various
    # locations in a source.
    #
    class Region
      # @return [String]
      attr_reader :namespace

      # @return [Symbol]
      attr_reader :scope

      # @return [Symbol]
      attr_reader :visibility

      # @return [Solargraph::Source]
      attr_reader :source

      # @param source [Source]
      # @param namespace [String]
      # @param scope [Symbol]
      # @param visibility [Symbol]
      def initialize source: Solargraph::Source.load_string(''), namespace: '',
                     scope: nil, visibility: :public
        @source = source
        @namespace = namespace
        @scope = scope
        @visibility = visibility
      end

      # @return [String]
      def filename
        source.filename
      end

      # Generate a new Region with the provided attribute changes.
      #
      # @param namespace [String, nil]
      # @param scope [Symbol, nil]
      # @param visibility [Symbol, nil]
      # @return [Region]
      def update namespace: nil, scope: nil, visibility: nil
        Region.new(
          source: source,
          namespace: namespace || self.namespace,
          scope: scope || self.scope,
          visibility: visibility || self.visibility
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
