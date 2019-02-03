module Solargraph
  module Pin
    class ProxyType < Base
      def initialize return_type: ComplexType::UNDEFINED, **splat
        super(splat)
        @return_type = return_type
      end

      def path
        @path ||= begin
          result = namespace.to_s
          result += '::' unless result.empty? or name.to_s.empty?
          result += name.to_s
        end
      end

      def context
        @return_type
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
