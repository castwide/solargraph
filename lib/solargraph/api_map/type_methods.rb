module Solargraph
  class ApiMap
    # Module functions for processing YARD types.
    #
    module TypeMethods
      module_function

      # Extract a namespace from a type.
      #
      # @example
      #   extract_namespace('String') => 'String'
      #   extract_namespace('Class<String>') => 'String'
      #
      # @param type [String]
      # @return [String]
      def extract_namespace type
        extract_namespace_and_scope(type)[0]
      end

      # Extract a namespace and a scope (:instance or :class) from a type.
      #
      # @example
      #   extract_namespace('String')            #=> ['String', :instance]
      #   extract_namespace('Class<String>')     #=> ['String', :class]
      #   extract_namespace('Module<Enumerable') #=> ['Enumberable', :class]
      #
      # @param type [String]
      # @return [Array] The namespace (String) and scope (Symbol).
      def extract_namespace_and_scope type
        scope = :instance
        result = type.to_s.gsub(/<.*$/, '')
        if (result == 'Class' or result == 'Module') and type.include?('<')
          result = type.match(/<([a-z0-9:_]*)/i)[1]
          scope = :class
        end
        [result, scope]
      end
    end
  end
end
