module Solargraph
  module Pin
    module Plugin
      class Method < Base
        attr_reader :name
        attr_reader :path
        attr_reader :return_type
        attr_reader :parameters
        attr_reader :scope
        attr_reader :visibility

        def initialize name:, path:, return_type:, parameters:
          @name = name
          @path = path
          @return_type = return_type
          @parameters = parameters
        end

        def completion_item_kind
          Solargraph::LanguageServer::CompletionItemKinds::METHOD
        end
      end
    end
  end
end
