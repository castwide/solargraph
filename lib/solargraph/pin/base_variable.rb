module Solargraph
  module Pin
    class BaseVariable < Base
      include NodeMethods

      def initialize source, node, namespace
        super
        @tried_to_detect_return_type = false
        @tried_to_resolve_return_type = false
      end

      def name
        node.children[0].to_s
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::VARIABLE
      end

      def return_type
        if @return_type.nil? and !@tried_to_detect_return_type
          @tried_to_detect_return_type = true
          if docstring.nil?
            @return_type ||= literal_from_assignment
          else
            tag = docstring.tag(:type)
            @return_type = tag.types[0] unless tag.nil?
          end
        end
        @return_type
      end

      def assignment_node
        @assignment_node ||= node.children[(node.type == :casgn ? 2 : 1)]
      end

      def nil_assignment?
        assignment_node.nil? or assignment_node.type == :nil
      end

      def signature
        @signature ||= resolve_node_signature(assignment_node)
      end

      # @param api_map [Solargraph::ApiMap]
      def resolve api_map
        if return_type.nil? and !@tried_to_resolve_return_type
          @tried_to_detect_return_type = true
          return nil if signature.nil? or signature.empty? or signature == name or signature.split('.').first.strip == name
          # @return_type = api_map.infer_signature_type(signature, namespace, call_node: node)
          fragment = source.fragment_for(assignment_node)
          fragment.whole_signature
          @return_type = api_map.signature_type(fragment) unless fragment.nil?
        end
      end

      def variable?
        true
      end

      private

      def literal_from_assignment
        infer_literal_node_type(assignment_node)
      end
    end
  end
end
