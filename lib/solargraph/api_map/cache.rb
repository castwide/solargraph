# frozen_string_literal: true

module Solargraph
  class ApiMap
    class Cache
      def initialize
        # @type [Hash{Array => Array<Pin::Method>}]
        @methods = {}
        # @type [Hash{Array<(Pin::Namespace, Pin::Namespace))> => Array<Pin::Base>}]
        @constants = {}
        @qualified_namespaces = {}
        @receiver_definitions = {}
      end

      # @return [Array<Pin::Method>]
      def get_methods fqns, scope, visibility, deep
        @methods[[fqns, scope, visibility.sort, deep]]
      end

      # @return [Array<Pin::Method>]
      def set_methods fqns, scope, visibility, deep, value
        @methods[[fqns, scope, visibility.sort, deep]] = value
      end

      # @return [Array<Pin::Base>]
      def get_constants namespace, context
        @constants[[namespace, context]]
      end

      # @param namespace [Pin::Namespace]
      # @param context [Pin::Namespace]
      # @param value [Array<Pin::Base>]
      # @return [void]
      def set_constants namespace, context, value
        @constants[[namespace, context]] = value
      end

      # @param name [String]
      # @param context [Pin::Namespace]
      # @return [String]
      def get_qualified_namespace name, context
        @qualified_namespaces[[name, context]]
      end

      # @param name [String]
      # @param context [Pin::Namespace]
      # @return [void]
      def set_qualified_namespace name, context, value
        @qualified_namespaces[[name, context]] = value
      end

      # @param path [String]
      def receiver_defined? path
        @receiver_definitions.key? path
      end

      # @return [Pin::Method]
      def get_receiver_definition path
        @receiver_definitions[path]
      end

      # @return [void]
      def set_receiver_definition path, pin
        @receiver_definitions[path] = pin
      end

      # @return [void]
      def clear
        @methods.clear
        @constants.clear
        @qualified_namespaces.clear
        @receiver_definitions.clear
      end

      # @return [Boolean]
      def empty?
        @methods.empty? &&
          @constants.empty? &&
          @qualified_namespaces.empty? &&
          @receiver_definitions.empty?
      end
    end
  end
end
