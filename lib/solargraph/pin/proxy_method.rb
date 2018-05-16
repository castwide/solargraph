module Solargraph
  module Pin
    # ProxyMethod serves as a quick, disposable shortcut for providing context
    # to type inference methods. ApiMap::Probe can treat it as an anonymous
    # method while analyzing signatures.
    #
    class ProxyMethod
      # @return [String]
      attr_reader :return_type

      def initialize return_type
        @return_type = return_type
      end

      # @return [String]
      def namespace
        @namespace ||= ApiMap::TypeMethods.extract_namespace(@return_type)
      end

      # @return [Integer]
      def kind
        Pin::METHOD
      end

      # @return [Symbol]
      def scope
        :instance
      end
    end
  end
end
