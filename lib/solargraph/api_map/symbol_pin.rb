module Solargraph
  class ApiMap
    class SymbolPin
      attr_reader :node
      attr_reader :namespace
      
      def initialize node
        @node = node
      end

      def suggestion
        @suggestion ||= generate_suggestion
      end

      private

      def generate_suggestion
        label = ":#{node.children[0]}"
        Suggestion.new(label, insert: label, kind: Suggestion::CONSTANT, documentation: nil, detail: 'Symbol', return_type: 'Symbol')
      end
    end
  end
end
