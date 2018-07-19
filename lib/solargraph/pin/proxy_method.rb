module Solargraph
  module Pin
    # ProxyMethod serves as a quick, disposable shortcut for providing context
    # to type inference methods. ApiMap::Probe can treat it as an anonymous
    # method while analyzing signatures.
    #
    class ProxyMethod < Base
      # @return [String]
      attr_reader :return_type

      def initialize *return_types
        @return_complex_types = ComplexType.parse(*return_types.reject(&:nil?))
      end

      # @return [String]
      def namespace
        # @namespace ||= ApiMap::TypeMethods.extract_namespace(return_type)
        @namespace ||= @return_complex_types.first.namespace
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
