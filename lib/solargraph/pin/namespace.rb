module Solargraph
  module Pin
    class Namespace < Pin::Base
      include Solargraph::NodeMethods

      def name
        @name ||= pack_name(node.children[0]).last.to_s
      end

      def path
        @path ||= (namespace.empty? ? '' : "#{namespace}::") + name
      end

      def kind
        @kind ||= (node.type == :class ? Solargraph::Suggestion::CLASS : Solargraph::Suggestion::MODULE)
      end

      def return_type
        @return_type ||= (node.type == :class ? 'Class' : 'Module') + "<#{path}>"
      end
    end
  end
end
