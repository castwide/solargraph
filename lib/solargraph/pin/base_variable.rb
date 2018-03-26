module Solargraph
  module Pin
    class BaseVariable < Base
      include NodeMethods

      def name
        node.children[0].to_s
      end

      def kind
        Solargraph::LanguageServer::CompletionItemKinds::VARIABLE
      end

      def return_type
        if @return_type.nil? and !docstring.nil?
          tag = docstring.tag(:type)
          @return_type = tag.types[0] unless tag.nil?
        end
        @return_type ||= literal_from_assignment
      end

      def assignment_node
        @assignment_node ||= node.children[(node.type == :casgn ? 2 : 1)]
      end

      def nil_assignment?
        assignment_node.type == :nil
      end

      def signature
        @signature ||= resolve_node_signature(node.children[(node.type == :casgn ? 2 : 1)])
      end

      def path
        name
      end

      private

      def literal_from_assignment
        infer_literal_node_type(assignment_node)
      end
    end
  end
end
