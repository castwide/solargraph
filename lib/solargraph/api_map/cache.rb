module Solargraph
  class ApiMap
    class Cache
      def initialize
        @signature_types = {}
        @assignment_node_types = {}
        @methods = {}
        @method_stacks = {}
        @constants = {}
        @qualified_namespaces = {}
      end

      def get_signature_type signature, namespace, scope
        @signature_types[[signature, namespace, scope]]
      end

      def has_signature_type?(signature, namespace, scope)
        @signature_types.has_key?([signature, namespace, scope])
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

      def get_methods fqns, scope, visibility, deep
        @methods[[fqns, scope, visibility.sort, deep]]
      end

      def set_methods fqns, scope, visibility, deep, value
        @methods[[fqns, scope, visibility.sort, deep]] = value
      end

      def get_method_stack fqns, name, scope
        @method_stacks[[fqns, name, scope]]
      end

      def set_method_stack fqns, name, scope, value
        @method_stacks[[fqns, name, scope]] = value
      end

      def get_constants namespace, context
        @constants[[namespace, context]]
      end

      def set_constants namespace, context, value
        @constants[[namespace, context]] = value
      end

      def get_qualified_namespace name, context
        @qualified_namespaces[[name, context]]
      end

      def set_qualified_namespace name, context, value
        @qualified_namespaces[[name, context]] = value
      end

      # @return [void]
      def clear
        @signature_types.clear
        @assignment_node_types.clear
        @methods.clear
        @method_stacks.clear
        @constants.clear
        @qualified_namespaces.clear
      end

      # @return [Boolean]
      def empty?
        @signature_types.empty? and
          @assignment_node_types.empty? and
          @methods.empty? and
          @method_stacks.empty? and
          @constants.empty? amd
          @qualified_namespaces.empty?
      end
    end
  end
end
