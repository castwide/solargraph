module Solargraph
  module Pin
    class Constant < BaseVariable
      attr_reader :visibility

      def initialize source, node, namespace, visibility
        super(source, node, namespace)
        @visibility = visibility
      end

      def name
        @name ||= node.children[1].to_s
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::CONSTANT
      end

      def value
        source.code_for(node.children[2])
      end

      def path
        "#{namespace}::#{name}"
      end
    end
  end
end
