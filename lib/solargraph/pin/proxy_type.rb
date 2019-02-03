module Solargraph
  module Pin
    class ProxyType < Base
      # @param location [Solargraph::Location]
      # @param namespace [String]
      # @param name [String]
      # @param return_type [ComplexType]
      # def initialize location, namespace, name, return_type
      # def initialize
      #   super(location, namespace, name, '')
      #   @return_complex_type = return_type
      # end

      def initialize return_type: ComplexType::UNDEFINED, **splat
        super(splat)
        @return_complex_type = return_type
      end

      def path
        @path ||= begin
          result = namespace.to_s
          result += '::' unless result.empty? or name.to_s.empty?
          result += name.to_s
        end
      end

      def context
        @return_complex_type
      end

      # @param return_type [ComplexType]
      # @return [ProxyType]
      def self.anonymous return_type
        parts = return_type.namespace.split('::')
        namespace = parts[0..-2].join('::').to_s
        name = parts.last.to_s
        # ProxyType.new(nil, namespace, name, return_type)
        ProxyType.new(
          closure: Solargraph::Pin::Namespace.new(name: namespace), return_type: return_type
        )
      end
    end
  end
end
