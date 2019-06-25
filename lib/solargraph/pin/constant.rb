# frozen_string_literal: true

module Solargraph
  module Pin
    class Constant < BaseVariable
      attr_reader :visibility

      def initialize visibility: :public, **splat
        super(splat)
        @visibility = visibility
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
