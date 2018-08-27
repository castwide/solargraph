module Solargraph
  module Pin
    class ProxyType < Base
      # @param location [Solargraph::Source::Location]
      # @param namespace [String]
      # @param name [String]
      # @param return_type [ComplexType]
      def initialize location, namespace, name, return_type
        super(location, namespace, name, '')
        @return_complex_type = return_type
      end

      # @param return_type [ComplexType]
      # @return [ProxyType]
      def self.anonymous return_type
        ProxyType.new(nil, nil, nil, return_type)
      end
    end
  end
end
