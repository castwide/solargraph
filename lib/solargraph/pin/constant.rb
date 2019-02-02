module Solargraph
  module Pin
    class Constant < BaseVariable
      attr_reader :visibility

      # def initialize location, namespace, name, comments, assignment, literal, context, visibility
      def initialize assignment: nil, literal: nil, visibility: :public, **splat
        # super(location, namespace, name, comments, assignment, literal, context)
        super(splat)
        @visibility = visibility
      end

      def kind
        Pin::CONSTANT
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::CONSTANT
      end

      # @return [Integer]
      def symbol_kind
        LanguageServer::SymbolKinds::CONSTANT
      end

      def path
        return name if context.namespace.to_s.empty?
        "#{context.namespace}::#{name}"
      end
    end
  end
end
