module Solargraph
  class ApiMap
    class Cache
      def initialize
        @methods = {}
        @constants = {}
        @qualified_namespaces = {}
      end

      def get_methods fqns, scope, visibility, deep
        @methods[[fqns, scope, visibility.sort, deep]]
      end

      def set_methods fqns, scope, visibility, deep, value
        @methods[[fqns, scope, visibility.sort, deep]] = value
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
        @methods.clear
        @constants.clear
        @qualified_namespaces.clear
      end

      # @return [Boolean]
      def empty?
        @methods.empty? &&
          @constants.empty? &&
          @qualified_namespaces.empty?
      end
    end
  end
end
