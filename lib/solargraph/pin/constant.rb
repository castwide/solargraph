module Solargraph
  module Pin
    class Constant < BaseVariable

      def name
        @name ||= node.children[1].to_s
      end

      def kind
        Solargraph::Suggestion::CONSTANT
      end

      def value
        source.code_for(node.children[2])
      end
    end
  end
end
