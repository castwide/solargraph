module Solargraph
  module Pin
    class Namespace < Pin::Base
      def name
        @name ||= namespace.split('::').last
      end

      def path
        @path ||= namespace
      end

      def kind
        @kind ||= (node.type == :class ? Solargraph::Suggestion::CLASS : Solargraph::Suggestion::MODULE)
      end
    end
  end
end
