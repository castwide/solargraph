# frozen_string_literal: true

module Solargraph
  module Pin
    class ProxyType < Base
      # @param return_type [ComplexType, ComplexType::UniqueType]
      # @param gates [Array<String>, nil] Namespaces to try while resolving non-rooted types
      # @param binder [ComplexType, ComplexType::UniqueType, nil]
      # @param gates [Array<String>, nil]
      # @param receiver_steps [::Array<::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol),
      #     ::Array(:cvar, ::Symbol), ::Array(:self_call, ::Symbol),
      #     ::Array(:call, ::Symbol),
      #     ::Array(:call, :[], ::Array<::Array(:literal, :str, ::String),
      #       ::Array(:literal, :sym, ::Symbol), ::Array(:literal, :int, ::Integer),
      #       ::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol),
      #       ::Array(:cvar, ::Symbol)>)>, nil] see #receiver_steps
      # @param receiver_bindings [::Array<Pin::LocalVariable>] see #receiver_bindings
      # @param [Hash{Symbol => Object}] splat
      def initialize return_type: ComplexType::UNDEFINED, binder: nil, gates: nil, receiver_steps: nil,
                     receiver_bindings: [], **splat
        super(**splat)
        @gates = gates
        @return_type = return_type
        @binder = binder if binder
        @receiver_steps = receiver_steps
        @receiver_bindings = receiver_bindings
      end

      # Pin::ExpressionNarrowing steps of the chain this pin is the
      # receiver of, e.g. [[:lvar, :pin], [:call, :location]] in
      # 'pin.location.filename', [] for self, or nil if not all variables,
      # attr_readers and pure calls; see Chain#define
      #
      # @return [::Array<::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol),
      #     ::Array(:cvar, ::Symbol), ::Array(:self_call, ::Symbol),
      #     ::Array(:call, ::Symbol),
      #     ::Array(:call, :[], ::Array<::Array(:literal, :str, ::String),
      #       ::Array(:literal, :sym, ::Symbol), ::Array(:literal, :int, ::Integer),
      #       ::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol),
      #       ::Array(:cvar, ::Symbol)>)>, nil]
      attr_reader :receiver_steps

      # The local variable #receiver_steps starts at, if any
      #
      # @return [::Array<Pin::LocalVariable>]
      attr_reader :receiver_bindings

      def context
        @return_type
      end

      # @param context [ComplexType, ComplexType::UniqueType] Used as context for this pin
      # @param closure [Pin::Namespace, nil] Used as the closure for this pin
      # @param binder [ComplexType, ComplexType::UniqueType, nil]
      # @return [ProxyType]
      # @param [Hash{Symbol => Object}] kwargs
      def self.anonymous context, closure: nil, binder: nil, **kwargs
        unless closure
          parts = context.namespace.split('::')
          # @sg-ignore Need to add nil check here
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
