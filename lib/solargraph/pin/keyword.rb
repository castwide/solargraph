module Solargraph
  module Pin
    class Keyword < Base
      def initialize name
        @name = name
      end

      def name
        @name
      end

      def kind
        Solargraph::LanguageServer::CompletionItemKinds::KEYWORD
      end
    end
  end
end
