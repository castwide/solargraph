module Solargraph
  module Pin
    class Symbol
      include Conversions

      attr_reader :location

      attr_reader :name

      def initialize location, name
        @name = name
        @location = location
      end

      def filename
        location.filename
      end

      def kind
        Pin::SYMBOL
      end

      def path
        nil
      end

      def identifier
        name
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::KEYWORD
      end

      def return_type
        'Symbol'
      end
    end
  end
end
