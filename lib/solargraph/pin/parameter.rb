module Solargraph
  module Pin
    class Parameter < Base
      def initialize source, node, namespace, name, return_type
        super(source, node, namespace)
        @name = name
        @return_type = return_type
      end

      def name
        @name
      end

      def return_type
        @return_type
      end

      def kind
        Solargraph::LanguageServer::CompletionItemKinds::PROPERTY
      end
    end
  end
end
