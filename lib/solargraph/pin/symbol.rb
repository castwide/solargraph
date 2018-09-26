module Solargraph
  module Pin
    class Symbol < Base
      # @param location [Solargraph::Location]
      # @param name [String]
      def initialize location, name
        @name = name
        @location = location
      end

      def namespace
        ''
      end

      def kind
        Pin::SYMBOL
      end

      def path
        ''
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::KEYWORD
      end

      def comments
        ''
      end

      def return_complex_type
        @return_complex_type ||= Solargraph::ComplexType::SYMBOL
      end

      def directives
        []
      end

      def deprecated?
        false
      end
    end
  end
end
