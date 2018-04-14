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

      # def name
      #   @name ||= node.children[1].to_s
      # end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::CONSTANT
      end

      # def value
      #   source.code_for(node.children[2])
      # end

      def path
        "#{namespace}::#{name}"
      end
    end
  end
end
