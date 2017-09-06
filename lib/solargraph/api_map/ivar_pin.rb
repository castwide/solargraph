module Solargraph
  class ApiMap
    class IvarPin
      attr_reader :node
      attr_reader :namespace
      attr_reader :scope
      attr_reader :docstring

      def initialize node, namespace, scope, docstring
        @node = node
        @namespace = namespace
        @scope = scope
        @docstring = docstring
      end

      def suggestion(api_map)
        @suggestion ||= generate_suggestion(api_map)
      end

      private

      def generate_suggestion(api_map)
        type = api_map.infer_assignment_node_type(node, namespace)
        Suggestion.new(node.children[0], kind: Suggestion::VARIABLE, documentation: docstring, return_type: type)
      end
    end
  end
end
