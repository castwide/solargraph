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
    end
  end
end
