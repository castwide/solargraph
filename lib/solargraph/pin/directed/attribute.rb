module Solargraph
  module Pin
    module Directed
      class Attribute < Solargraph::Pin::Attribute
        def initialize source, node, namespace, access, docstring, name
          super(source, node, namespace, access, docstring)
          @name = name
        end

        def name
          @name
        end

        def completion_item_kind
          Solargraph::LanguageServer::CompletionItemKinds::METHOD
        end
      end
    end
  end
end
