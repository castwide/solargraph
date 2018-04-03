module Solargraph
  module Pin
    class Keyword < Base
      def initialize name
        @name = name
      end

      def name
        @name
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::KEYWORD
      end

      def identifier
        # HACK: A cheap way to make keyword identifiers unique
        object_id
      end
    end
  end
end
