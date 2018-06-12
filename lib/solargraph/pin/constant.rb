module Solargraph
  module Pin
    class Constant < BaseVariable
      attr_reader :visibility

      def initialize location, namespace, name, docstring, signature, literal, context, visibility
        super(location, namespace, name, docstring, signature, literal, context)
        @visibility = visibility
      end

      def kind
        Pin::CONSTANT
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::CONSTANT
      end

      # @return [Integer]
      def symbol_kind
        LanguageServer::SymbolKinds::CONSTANT
      end

      def path
        "#{namespace}::#{name}"
      end
    end
  end
end
