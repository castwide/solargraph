module Solargraph
  class ApiMap
    class Cache
      def initialize
        @signature_types = {}
        @assignment_node_types = {}
      end

      def get_signature_type signature, namespace, scope
        @signature_types[[signature, namespace, scope]]
      end

      def set_signature_type signature, namespace, scope, value
        @signature_types[[signature, namespace, scope]] = value
      end

      def get_assignment_node_type node, namespace
        @assignment_node_types[[node, namespace]]
      end

      def set_assignment_node_type node, namespace, value
        @assignment_node_types[[node, namespace]] = value
      end

      def clear
        @signature_types.clear
        @assignment_node_types.clear
      end
    end
  end
end
