# frozen_string_literal: true

module Solargraph
  module Pin
    class ProxyType < Base
      # @param return_type [ComplexType]
      def initialize return_type: ComplexType::UNDEFINED, **splat
        super(**splat)
        @return_type = return_type
      end

      def context
        @return_type
      end

      # @param return_type [ComplexType]
      # @return [ProxyType]
      def self.anonymous return_type, source: nil
        parts = return_type.namespace.split('::')
        namespace = parts[0..-2].join('::').to_s
        # name = parts.last.to_s
        # ProxyType.new(nil, namespace, name, return_type)
        ProxyType.new(
          closure: Solargraph::Pin::Namespace.new(name: namespace, source: :proxy_type), return_type: return_type, source: :source
        )
      end
    end
  end
end
