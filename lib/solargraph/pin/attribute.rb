module Solargraph
  module Pin
    class Attribute < BaseMethod
      # @return [Symbol] :reader or :writer
      attr_reader :access

      def initialize visibility: :public, access: :reader, node: nil, **splat
        super(splat)
        @access = access
        @scope = scope
        @visibility = visibility
      end

      def kind
        Solargraph::Pin::ATTRIBUTE
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::PROPERTY
      end

      def symbol_kind
        Solargraph::LanguageServer::SymbolKinds::PROPERTY
      end

      def path
        @path ||= namespace + (scope == :instance ? '#' : '.') + name
      end

      def parameters
        # Since attributes are generally equivalent to methods, treat
        # them as methods without parameters
        []
      end

      def parameter_names
        []
      end
    end
  end
end
