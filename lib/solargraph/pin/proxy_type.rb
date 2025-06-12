# frozen_string_literal: true

module Solargraph
  module Pin
    class ProxyType < Base
      # @param return_type [ComplexType]
      def initialize return_type: ComplexType::UNDEFINED, binder: nil, **splat
        super(**splat)
        @return_type = return_type
        @binder = binder if binder
      end

      def context
        @return_type
      end

      # @param context [ComplexType, ComplexType::UniqueType] Used as context for this pin
      # @param closure [Pin::Namespace, nil] Used as the closure for this pin
      # @param binder [ComplexType, ComplexType::UniqueType, nil]
      # @return [ProxyType]
      def self.anonymous context, closure: nil, binder: nil, **kwargs
        unless closure
          parts = context.namespace.split('::')
          namespace = parts[0..-2].join('::').to_s
          closure = Solargraph::Pin::Namespace.new(name: namespace, source: :proxy_type)
        end
        # name = parts.last.to_s
        # ProxyType.new(nil, namespace, name, return_type)
        ProxyType.new(
          closure: closure, return_type: context, binder: binder || context, **kwargs
        )
      end
    end
  end
end
