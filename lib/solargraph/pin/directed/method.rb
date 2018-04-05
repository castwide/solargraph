module Solargraph
  module Pin
    module Directed
      class Method < Solargraph::Pin::Method
        def initialize source, node, namespace, scope, visibility, docstring, name, return_type = nil
          super(source, node, namespace, scope, visibility)
          @docstring = docstring
          @name = name
          @return_type = return_type
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
