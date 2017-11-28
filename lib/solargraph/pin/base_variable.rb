module Solargraph
  module Pin
    class BaseVariable < Base
      include NodeMethods

      def name
        node.children[0].to_s
      end

      def kind
        Solargraph::Suggestion::VARIABLE
      end

      def return_type
        if @return_type.nil? and !docstring.nil?
          tag = docstring.tag(:type)
          @return_type = tag.types[0] unless tag.nil?
        end
        @return_type ||= literal_from_assignment
      end

      def nil_assignment?
        node.children[(node.type == :casgn ? 2 : 1)].type == :nil
      end

      def signature
        @signature ||= resolve_node_signature(node.children[(node.type == :casgn ? 2 : 1)])
      end

      private

      def literal_from_assignment
        infer_literal_node_type(node.children[(node.type == :casgn ? 2 : 1)])
      end
    end
  end
end
